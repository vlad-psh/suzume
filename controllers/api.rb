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
  return Artist.all.order(title: :asc).map do |a|
    {
      id: a.id,
      title: a.romaji.present? ? "#{a.title} (#{a.romaji})" : a.title,
      aliases: a.aliases,
      tags: a.tags.pluck(:title)
    }
  end.to_json
end

get :api_artist do
  protect!
  artist = Artist.find(params[:id])
  halt(404, 'Not found') unless artist.present?
  return artist.api_json
end

get :api_release do
  protect!
  release = Release.find(params[:id])
  halt(404, 'Not found') unless release.present?

  return {
    release: release.api_hash,
    images: release.abyss_images,
  }.to_json
end

post :api_release_cover do
  protect!

  release = Release.find_by(id: params[:id])
  folder = Folder.find_by(id: params[:folder_id])
  halt(404, 'Not found') if release.blank? || folder.blank? || !folder.contains_file?(params[:filename])

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
  contents = folder.contents

  return folder.serializable_hash.merge({
    release: folder.release ? folder.release.api_hash : nil,
    artist: folder.release ? [folder.release.artist.id, folder.release.artist.title] : nil,
    files: contents[:files],
    name: (folder.is_symlink ? '🔗' : '') + folder.name,
    parents: folder.parents.map{|i| [i.id, (folder.is_symlink ? '🔗' : '') + File.basename(i.path)]},
    subfolders: contents[:dirs].map{|f|
      [f.id,
      (f.is_symlink ? '🔗' : '') + f.path,
       f.release ? [f.release.artist_id, f.release.artist.title] : nil
      ]
    },
  }).to_json
end

get :api_autocomplete_artist do
  protect!

  q = "%#{params[:query]}%"
  artists = Artist.where('title ILIKE ? OR romaji ILIKE ? OR aliases ILIKE ?', q, q, q).limit(30)

  artists.map do |a|
    {
      id: a.id,
      title: a.title,
      romaji: a.romaji,
      aliases: a.aliases,
      releases: a.releases.map { |r| { id: r.id, title: r.title, year: r.year, romaji: r.romaji, release_type: r.release_type } }
    }
  end.to_json
end

patch :api_rating do
  track = Track.find_by(uid: params[:uid])
  halt(404, 'Not found') unless track.present?
  track.update(rating: params[:rating])
  return track.rating.to_s
end
