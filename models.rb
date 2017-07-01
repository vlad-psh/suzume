module NoteParent
  def simple_type
    if self.kind_of?(Artist)
      return :p
    elsif self.kind_of?(Album)
      return :r
    elsif self.kind_of?(Track)
      return :t
    else
      throw StandardError.new("Unknown NoteParent type: #{self.class}")
    end
  end

  def notes
    return Note.where(parent_type: simple_type, parent_id: id)
  end
end

class Artist < ActiveRecord::Base
  include NoteParent
  has_and_belongs_to_many :albums
  has_and_belongs_to_many :tags
end

class Album < ActiveRecord::Base
  include NoteParent
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :tags
  has_many :tracks

  def full_path
    return @_full_path if @_full_path
    _artist = artists.first
    @_full_path = File.join($library_path, _artist.filename, filename)
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
    filenames = search_tracks

    tracks.each do |t|
      filenames.delete(t.filename) if filenames.include?(t.filename)
    end

    filenames.each do |fn|
      tracks << Track.create(album: self, filename: fn)
    end

    return tracks.order(filename: :asc)
  end
end

class Tag < ActiveRecord::Base
  has_many :tag_relations
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :albums
end

class TagRelation < ActiveRecord::Base
  belongs_to :tag
end

class ArtistsTag < ActiveRecord::Base
end
class AlbumsTag < ActiveRecord::Base
end

class Track < ActiveRecord::Base
  include NoteParent
  belongs_to :album
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
