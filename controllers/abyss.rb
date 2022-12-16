paths \
  abyss_file: '/abyss/:folder_id/file/:md5',
  abyss_set_cover: '/abyss/:folder_id/set_cover/:md5',
  abyss_link_release: '/api/abyss/:folder_id/link'

get :abyss_file do
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename

  filepath = File.join(folder.path, filename)
  headers['X-Accel-Redirect'] = File.join("/nginx-abyss", filepath)
  headers['Content-Disposition'] = "inline; filename=\"#{filename}\""
  headers['Content-Type'] = get_mime(filename)
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

post :abyss_set_cover do
  f = Folder.find(params[:folder_id])
  details = f.files[params[:md5]]

  throw StandardError.new("File with MD5 #{md5} doesn't exist in folder #{f.id}") unless details.present?
  throw StandardError.new("File with MD5 #{md5} is not an image file") if details['type'] != 'image'

  FileUtils.mkdir_p(f.release.full_path) unless File.exist?(f.release.full_path)

  # Delete old covers
  Dir.children(f.release.full_path).select{|i| i =~ /(cover|thumb)\./}.each do |imgname|
    File.delete( File.join(f.release.full_path, imgname) )
  end

  oldfilepath = File.join(f.full_path, details['fln'])
  extension = details['fln'].downcase.gsub(/.*\.([^\.]*)/, "\\1")
  newfilepath = File.join(f.release.full_path, "cover.#{extension}")
  thumbfilepath = File.join(f.release.full_path, "thumb.#{extension}")
  FileUtils.copy(oldfilepath, newfilepath)

  img = MiniMagick::Image.open(newfilepath)
  if [img.width, img.height].max > 400
    img.resize("400x400>")
    img.write(thumbfilepath)
  else
    FileUtils.copy(newfilepath, thumbfilepath)
  end
  img.destroy! # remove temp file
  f.release.update(cover: extension)

  return {result: 'ok'}.to_json
end
