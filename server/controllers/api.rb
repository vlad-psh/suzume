paths \
  api_index: '/api/index',
  api_artist: '/api/artist/:id',
  api_release: '/api/release/:id',
  api_release_cover: '/api/release/:id/cover',
  api_tracks: '/api/tracks',
  api_abyss: '/api/abyss/:id',
  api_autocomplete_artist: '/api/autocomplete/artist',
  api_rating: '/api/rating/:uid'

get :api_index do
  protect!
  return ArtistSerializer.render(Artist.all.order(title: :asc), view: :index)
end

get :api_artist do
  protect!
  artist = Artist.find(params[:id]) || halt(404, 'Artist not found')
  return ArtistSerializer.render(artist, view: :extended)
end

get :api_release do
  protect!

  release = Release.find(params[:id]) || halt(404, 'Not found')

  return {
    release: ReleaseSerializer.render_as_hash(release, view: :extended),
    images: release.abyss_images,
  }.to_json
end

post :api_release_cover do
  protect!

  release = Release.find_by(id: params[:id]) || halt(404, 'Release not found')
  folder = Folder.find_by(id: params[:folder_id]) || halt(404, 'Folder not found')
  halt(404, 'File not found') if !folder.contains_file?(params[:filename])

  release.set_cover!(File.join(folder.full_path, params[:filename]))

  halt 200
end

patch :api_tracks do
  protect!

  halt 403 unless params[:tracks].present? && params[:tracks].is_a?(Hash)

  params[:tracks].each do |k,v|
    Track.find_by(uid: k)&.update(title: v.strip)
  end

  halt 200
end

get :api_abyss do
  protect!
  folder = Folder.eager_load(release: :artist).find_by(id: params[:id]) || Folder.root
  return FolderSerializer.render(folder)
end

get :api_autocomplete_artist do
  protect!

  q = "%#{params[:query]}%"
  artists = Artist.where('title ILIKE ? OR romaji ILIKE ? OR aliases ILIKE ?', q, q, q).limit(30)

  return ArtistSerializer.render(artists, view: :autocomplete)
end

patch :api_rating do
  track = Track.find_by(uid: params[:uid]) || halt(404, 'Not found')
  track.update(rating: params[:rating])
  return track.rating.to_s
end
