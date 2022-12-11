class Track < ActiveRecord::Base
  belongs_to :release
  belongs_to :folder, optional: true
  has_one :artist, through: :release
  has_and_belongs_to_many :playlists

  before_create :assign_uid, if: -> {uid.blank?}
  before_create :auto_properties

  before_update :on_rating_change, if: :rating_changed?

  before_destroy :unlink_file!

  def <=>(other)
    original_filename <=> other.original_filename
  end

  def filename
    uid + '.' + extension
  end

  def directory
    File.join(release_id[0..1], release_id[2..])
  end

  def full_path
    File.join($library_path, directory, filename)
  end

  def abyss_full_path
    return nil unless folder.present?

    File.join(folder.full_path, original_filename)
  end

  def exists_in_library?
    File.exist?(full_path)
  end

  def exists_in_abyss?
    return false unless abyss_full_path.present?

    File.exist?(abyss_full_path)
  end

  def any_full_path
    return full_path if exists_in_library?
    return abyss_full_path if exists_in_abyss?

    nil
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

  def waveform
    w = read_attribute(:waveform)
    update_waveform! if w.blank? || w['version'] < WaveformService::VERSION

    read_attribute(:waveform)['data']
  end

  def delete_from_filesystem
    File.delete(full_path) if File.exist?(full_path)
    self.update(purged: true)
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
      title: title.presence || stripped_filename,
      filename: original_filename,
      rating: rating,
      dur: duration_string,
      br: "#{mediainfo['br'].to_i/1000}#{mediainfo['brm']}",
      purged: purged,
    }
  end

  def api_json
    return api_hash.to_json
  end

  def stripped_filename
    return original_filename.gsub(/\.mp3$/i, '').gsub(/\.m4a$/i, '').gsub(/^[0-9\-\.]* (- )?/, '')
  end

  private
  def update_waveform!
    file_path = any_full_path
    self.update(waveform: WaveformService.generate(file_path)) if file_path.present?
  end

  def assign_uid
    while Track.where(uid: (_uid = SecureRandom.hex(4))).present? do end
    self.uid = _uid
  end

  def auto_properties
    self.extension = self.original_filename.gsub(/.*\./, '') unless self.extension
  end

  def on_rating_change
    if rating >= 0
      link_file! unless exists_in_library?
    elsif rating < 0
      unlink_file!
      self.purged = true if !exists_in_abyss?
    end
  end

  def link_file!
    return unless abyss_full_path

    FileUtils.mkdir_p(release.full_path) unless Dir.exist?(release.full_path)
    FileUtils.cp(abyss_full_path, full_path)
    if extension == 'mp3'
      `id3 -2 -rAPIC -rGEOB -s 0 -R '#{full_path}'`
#    elsif extension == 'm4a'
#      `mp4art --remove '#{full_path}'`
#      `mp4file --optimize '#{full_path}'`
    end
  end

  def unlink_file!
    FileUtils.rm(full_path) if exists_in_library?
  end
end
