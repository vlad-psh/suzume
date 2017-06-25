class Artist < ActiveRecord::Base
  has_and_belongs_to_many :albums
  has_and_belongs_to_many :tags
end

class Album < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :tags

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
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :albums
end
