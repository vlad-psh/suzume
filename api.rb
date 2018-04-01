get :api_index do
  result = {artists: [], albums: [], songs: []}
  Performer.all.order(title: :asc).each do |a|
    result[:artists] << {id: a.id, title: a.title}
  end
  return result.to_json
end

get :api_artist do
  artist = Performer.find(params[:id])

  return {error: '404'}.to_json unless artist

  result = {artists: [], albums: [], songs: []}
  artist.releases.joins(:records).merge(Record.all).distinct.order(year: :desc).each do |a|
    result[:albums] << {id: a.id, title: a.title}
  end
  return result.to_json
end

get :api_album do
  album = Release.find(params[:id])

  return {error: '404'}.to_json unless album

  return {
    artists: [],
    albums: [],
    songs: album.records.map{|t| {id: t.id, filename: strip_filename(t.original_filename)} }
  }.to_json
end

get :api_cover_orig do
  release = Release.find(params[:id])
  redirect release.download_cover
end

get :api_cover_thumb do
  release = Release.find(params[:id])
  redirect release.download_thumb
end

get :api_download_track do
  record = Record.find(params[:id])
  redirect record.download_path
end
