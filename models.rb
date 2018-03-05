module MusicObject
  def self.find(obj_type, obj_id)
    return case obj_type.to_sym
      when :p then Artist.find(obj_id)
      when :r then Album.find(obj_id)
      when :t then Track.find(obj_id)
      else throw StandardError.new("Unknown parent_type: #{obj_type}")
    end
  end

  def simple_type
    if self.kind_of?(Artist)
      return :p
    elsif self.kind_of?(Album)
      return :r
    elsif self.kind_of?(Track)
      return :t
    else
      throw StandardError.new("Unknown MusicObject type: #{self.class}")
    end
  end

  def notes
    return Note.where(parent_type: simple_type, parent_id: id)
  end
end

class Artist < ActiveRecord::Base
  include MusicObject
  has_and_belongs_to_many :albums

  def full_path
    return @_full_path if @_full_path
    @_full_path = File.join($library_path, filename)
  end

  def xdestroy!
    if Performer.find_by(old_id: self.id)
      self.albums.each do |a|
        # destroy only 'not processed' albums
        a.xdestroy! unless Release.find_by(old_id: a.id)
      end
      self.status = 'processed'
      self.save
    else
      self.albums.each {|a| a.xdestroy!}
      self.notes.destroy_all

      self.destroy
    end
  end
end

class Album < ActiveRecord::Base
  include MusicObject
  has_and_belongs_to_many :artists
  has_many :tracks

  def full_path
    return @_full_path if @_full_path
    _artist = artists.first
    @_full_path = File.join(_artist.full_path, filename)
  end

  def search_tracks
    old_pwd = Dir.pwd
    Dir.chdir(full_path)
    tracks  = Dir.glob("**/*.mp3", File::FNM_CASEFOLD)
    tracks += Dir.glob("**/*.m4a", File::FNM_CASEFOLD)
    Dir.chdir(old_pwd)
    return tracks.sort
  end

  def all_tracks
    if Dir.exist?(full_path)
      filenames = search_tracks

      tracks.each do |t|
        filenames.delete(t.filename) if filenames.include?(t.filename)
      end

      filenames.each do |fn|
        tracks << Track.create(album: self, filename: fn)
      end
    end

    return tracks.order(filename: :asc)
  end

  def cover_path
    jpg_path = File.expand_path("orig/#{self.id}.jpg", $covers_path)
    return jpg_path if File.exist?(jpg_path)

    png_path = File.expand_path("orig/#{self.id}.png", $covers_path)
    return png_path if File.exist?(png_path)

    return nil
  end

  def thumb_path
    jpg_path = File.expand_path("thumb/#{self.id}.jpg", $covers_path)
    return jpg_path if File.exist?(jpg_path)
    
    png_path = File.expand_path("thumb/#{self.id}.png", $covers_path)
    return png_path if File.exist?(png_path)

    return nil
  end

  def xdestroy!
    throw StandardError.new("Linked to Release") if Release.find_by(old_id: self.id)

    self.tracks.each {|t| t.xdestroy!}
    self.notes.destroy_all

    if File.exists?(self.full_path)
      removed_artist_path = File.join($library_path, 'removed', self.artists.first.filename)
      FileUtils.mkdir(removed_artist_path) unless File.exists?(removed_artist_path)

      FileUtils.mv(self.full_path, removed_artist_path) # move

      removed_album_path = File.join($library_path, 'removed',
                self.artists.first.filename,
                "#{self.year} #{self.title} [#{self.primary_type}]".gsub(/\//, '_'))
      FileUtils.mv(File.join(removed_artist_path, self.filename), removed_album_path) # rename to "year title [type]"
    end

    self.destroy
  end

  def update_mediainfo!
    all_tracks.each do |t|
      t.update_mediainfo!
    end
  end

  def create_folder!
    FileUtils.mkdir_p(self.full_path) unless File.exist?(self.full_path)
  end
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :performers
end

class Track < ActiveRecord::Base
  include MusicObject
  belongs_to :album
  before_create :update_mediainfo

  def lyrics
    if self.lyrics_json
      return JSON.parse(self.lyrics_json)
    else
      return {}
    end
  end

  def lyrics=(val)
    self.lyrics_json = val.to_json
  end

  def full_path
    return @_full_path if @_full_path
    @_full_path = File.join(album.full_path, filename)
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

  def xdestroy!
    self.notes.destroy_all
    self.destroy
  end
end

class Note < ActiveRecord::Base
  def parent
    result = case parent_type
      when :p then Artist.find(parent_id)
      when :r then Album.find(parent_id)
      when :t then Track.find(parent_id)
      else throw StandardError.new("Unknown parent_type: #{parent_type}")
    end
  end
end

class Performer < ActiveRecord::Base
  has_many :releases
  has_many :records, through: :releases
  has_and_belongs_to_many :tags

  def sorted_records
    result = {}
    rr = records.includes(:release)

    prev_release = nil
    rr.sort_by {|rec| rec.release.title}.each do |r|
      result[r.release] ||= []
      result[r.release] << r
    end

    return result
  end
end

class Release < ActiveRecord::Base
  belongs_to :performer
  has_many :records

  def full_path
    return nil unless self.directory
    path = File.join($library_path, self.directory)
    return File.exist?(path) ? path : nil
  end

  def download_cover
    return nil unless path = self.full_path

    %w(jpg png).each do |ext|
      return File.join('/rdownload', self.directory, "cover.#{ext}") if File.exist?(File.join(path, "cover.#{ext}"))
    end

    return nil
  end

  def download_thumb
    return nil unless path = self.full_path

    %w(jpg png).each do |ext|
      return File.join('/rdownload', self.directory, "thumb.#{ext}") if File.exist?(File.join(path, "thumb.#{ext}"))
    end

    return nil
  end
end

class Record < ActiveRecord::Base
  belongs_to :release
  has_one :performer, through: :release
  has_and_belongs_to_many :playlists

  def full_path
    File.join($library_path, directory, filename)
  end

  def download_path
    File.join('/rdownload', directory, filename)
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
end

class Playlist < ActiveRecord::Base
  has_and_belongs_to_many :records
end
