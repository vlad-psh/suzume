class Artist < ActiveRecord::Base
  has_and_belongs_to_many :albums
  has_and_belongs_to_many :tags

  def notes
    return Note.lookup(self)
  end
end

class Album < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :tags
  has_many :tracks

  def full_path
    return @_full_path if @_full_path
    _artist = artists.first
    @_full_path = File.join($library_path, _artist.filename, filename)
  end

  def all_tracks
    old_pwd = Dir.pwd
    Dir.chdir(full_path)
    tracks  = Dir.glob("**/*.mp3", File::FNM_CASEFOLD)
    tracks += Dir.glob("**/*.m4a", File::FNM_CASEFOLD)
    Dir.chdir(old_pwd)
    return tracks.sort
  end

  def notes
    return Note.lookup(self)
  end
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :albums
end

class Track < ActiveRecord::Base
  belongs_to :album

  def notes
    return Note.lookup(self)
  end
end

class Note < ActiveRecord::Base
  def self.lookup(obj)
    if obj.kind_of?(Artist)
      return Note.where(parent_type: 'p', parent_id: obj.id)
    elsif obj.kind_of?(Album)
      return Note.where(parent_type: 'r', parent_id: obj.id)
    elsif obj.kind_of?(Track)
      return Note.where(parent_type: 't', parent_id: obj.id)
    else
      return nil
    end
  end

  def parent
    result = case parent_type
      when 'p' then Artist.find(parent_id)
      when 'r' then Album.find(parent_id)
      when 't' then Track.find(parent_id)
      else throw StandardError.new("Unknown parent_type: #{parent_type}")
    end
  end
end
