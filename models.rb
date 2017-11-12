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

  def tags
    return TagRelation.includes(:tag).where(parent_type: simple_type, parent_id: id).map{|i|i.tag}
  end
end

class Artist < ActiveRecord::Base
  include MusicObject
  has_and_belongs_to_many :albums

  def full_path
    return @_full_path if @_full_path
    @_full_path = File.join($library_path, filename)
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
end

class Tag < ActiveRecord::Base
  has_many :tag_relations

  def artists
    return Artist.where(id: TagRelation.where(parent_type: :p, tag_id: id).pluck(:parent_id))
  end

  def albums
    return Album.where(id: TagRelation.where(parent_type: :r, tag_id: id).pluck(:parent_id))
  end

  def tracks
    return Track.where(id: TagRelation.where(parent_type: :t, tag_id: id).pluck(:parent_id))
  end
end

class TagRelation < ActiveRecord::Base
  belongs_to :tag
end

class Track < ActiveRecord::Base
  include MusicObject
  belongs_to :album

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
end

class Release < ActiveRecord::Base
  belongs_to :performer
  has_many :records
end

class Record < ActiveRecord::Base
  belongs_to :release
end
