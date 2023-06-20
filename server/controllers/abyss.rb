paths \
  abyss_folder:       '/api/abyss/:folder_id', # delete
  abyss_link_release: '/api/abyss/:folder_id/link' # post

delete :abyss_folder do
  protect!

  folder = Folder.find(params[:folder_id]) || halt(404, 'Folder not found')
  folder.destroy!

  halt 200
end

post :abyss_link_release do
  protect!

  folder = Folder.find(params[:folder_id]) || halt(404, 'Folder not found')
  artist = find_or_create_artist(params[:artist])
  release = find_or_create_release(params[:release], artist)

  folder.link_to_release!(release)

  halt 200
end

def find_or_create_artist(props)
  return Artist.find(props[:id]) || halt(404, 'Artist not found') if props[:id].present?

  throw StandardError.new("Artist title cannot be blank") if params[:artist][:title].blank?

  Artist.create(
      title:   props[:title],
      romaji:  props[:romaji].presence,
      aliases: props[:aliases].presence,
  )
end

def find_or_create_release(props, artist)
  return Release.find_by(id: props[:id]) || halt(404, 'Release not found') if props[:id].present?

  # TODO: if title is empty, append tracks to 'no album'
  throw StandardError.new("Release title cannot be blank") if props[:title].blank?

  Release.create(
    artist:       artist,
    title:        props[:title],
    year:         props[:year].presence,
    romaji:       props[:romaji].presence,
    release_type: props[:release_type].presence,
  )
end
