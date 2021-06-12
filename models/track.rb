class Track < ActiveRecord::Base
  belongs_to :release
  belongs_to :folder, optional: true
  has_one :artist, through: :release
  has_and_belongs_to_many :playlists

  before_create :assign_uid, if: -> {uid.blank?}
  before_create :auto_properties
  after_create :link_file!, if: -> {rating != nil && rating >= 0 && !stored?}

  before_update :on_rating_change, if: :rating_changed?

  before_destroy :unlink_file!

  def filename
    uid + '.' + extension
  end

  def directory
    File.join(release_id[0..1], release_id[2..])
  end

  def full_path
    File.join($library_path, directory, filename)
  end

  def title
    t = read_attribute(:title)
    t.present? ? t : stripped_filename
  end

  def stored?
    File.exist?(full_path)
  end

  def update_mediainfo
    p = full_path
    p = File.join(folder.full_path, original_filename) unless File.exist?(p)
    return unless File.exist?(p)

    m = MediaInfoNative::MediaInfo.new()
    m.open_file(p)
    self.mediainfo = {
      dur: m.audio.duration,
      br:  m.audio.bit_rate,
      brm: m.audio.bit_rate_mode,
      sr:  m.audio.sample_rate,
      ch:  m.audio.channels
    }
    m.close
  end

  def update_mediainfo!
    self.update_mediainfo
    self.save
  end

  def delete_from_filesystem
    File.delete(full_path) if File.exist?(full_path)
    self.delete
  end

  def duration_string
    total_s = mediainfo['dur'].to_i / 1000
    s = total_s % 60
    total_m = total_s / 60
    m = total_m % 60
    h = total_m / 60
    return [h > 0 ? h : nil, h > 0 ? '%02d' % m : m, '%02d' % s].compact.join(':')
  end

  def api_hash
    return {
      uid: uid,
      title: stripped_filename,
      rating: rating,
      dur: duration_string,
      br: "#{mediainfo['br'].to_i/1000}#{mediainfo['brm']}"
    }
  end

  def api_json
    return api_hash.to_json
  end

  def stripped_filename
    return original_filename.gsub(/\.mp3$/i, '').gsub(/\.m4a$/i, '').gsub(/^[0-9\-\.]* (- )?/, '')
  end

  private
  def assign_uid
    while Track.where(uid: (_uid = SecureRandom.hex(4))).present? do end
    self.uid = _uid
  end

  def auto_properties
    self.extension = self.original_filename.gsub(/.*\./, '') unless self.extension
  end

  def on_rating_change
    r1 = changed_attributes['rating']
    r2 = self.rating

    if (r1 == nil || r1 < 0) && r2 >= 0
      link_file!
    elsif r1 != nil && r1 >= 0 && (r2 == nil || r2 < 0)
      FileUtils.rm(full_path)
    end
  end

  def link_file!
    FileUtils.mkdir_p(release.full_path) unless Dir.exist?(release.full_path)
    FileUtils.cp(File.join(folder.full_path, original_filename), full_path)
    if extension == 'mp3'
      `id3 -2 -rAPIC -rGEOB -s 0 -R '#{full_path}'`
#    elsif extension == 'm4a'
#      `mp4art --remove '#{full_path}'`
#      `mp4file --optimize '#{full_path}'`
    end
  end

  def unlink_file!
    FileUtils.rm(full_path) if stored?
  end
end
