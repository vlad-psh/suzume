module TulipHelpers
  def mb_artist_search_path(artist)
    return "https://musicbrainz.org/search?query=#{artist.gsub(/[&?=]/, '')}&type=artist&method=indexed"
  end
end
