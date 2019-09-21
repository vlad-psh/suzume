class Record < ActiveRecord::Base
  belongs_to :release
  has_one :performer, through: :release
  has_and_belongs_to_many :playlists

  def filename
    uid + '.' + extension
  end

  def full_path
    File.join($library_path, directory, filename)
  end

  def update_mediainfo
    return unless File.exist?(self.full_path)
    m = MediaInfoNative::MediaInfo.new()
    m.open_file(self.full_path)
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

  def api_hash
    return {
      uid: uid,
      title: stripped_filename,
      rating: rating
    }
  end

  def api_json
    return api_hash.to_json
  end

  def stripped_filename
    return original_filename.gsub(/\.mp3$/i, '').gsub(/\.m4a$/i, '').gsub(/^[0-9\-\.]* (- )?/, '')
  end
end
