get :api_index do
  result = {artists: [], albums: [], songs: []}
  Artist.all.order(title: :asc).each do |a|
    result[:artists] << {id: a.id, title: a.title}
  end
  return result.to_json
end

get :api_artist do
  artist = Artist.find(params[:id])

  return {error: '404'}.to_json unless artist

  result = {artists: [], albums: [], songs: []}
  artist.albums.order(year: :desc).each do |a|
    result[:albums] << {id: a.id, title: a.title}
  end
  return result.to_json
end


get :api_album do
  album = Album.find(params[:id])

  return {error: '404'}.to_json unless album

  return {artists: [], albums: [], songs: album.all_tracks}.to_json
end

