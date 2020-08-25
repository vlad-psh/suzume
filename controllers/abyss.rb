paths \
  abyss_file: '/abyss/:folder_id/file/:md5',
  abyss_set_cover: '/abyss/:folder_id/set_cover/:md5',
  abyss_set_folder_info: '/abyss/:folder_id/info'

def value_or_nil(v)
  return v.blank? ? nil : v
end

get :abyss_file do
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename

  filepath = File.join(folder.path, filename)
  headers['X-Accel-Redirect'] = File.join("/nginx-abyss", filepath)
  headers['Content-Disposition'] = "inline; filename=\"#{filename}\""
  headers['Content-Type'] = get_mime(filename)
end

post :abyss_set_folder_info do
  protect!
  folder = Folder.find(params[:folder_id])

  artist = Artist.find(params[:artist_id]) if params[:artist_id].present?
  unless artist.present?
    throw StandardError.new("Artist title cannot be blank") if params[:artist_title].blank?
    artist = Artist.create(
        title: params[:artist_title],
        romaji: value_or_nil(params[:artist_romaji]),
        aliases: value_or_nil(params[:artist_aliases])
    )
  end

  release = Release.find_by(id: params[:release_id]) if params[:release_id].present?
  unless release.present?
    throw StandardError.new("Release title cannot be blank") if params[:release_title].blank?
    # TODO: if title is empty, append tracks to 'no album'

    release = Release.create(
      artist: artist,
      title: params[:release_title],
      year: value_or_nil(params[:release_year]),
      romaji: value_or_nil(params[:release_romaji]),
      format: value_or_nil(params[:release_format]),
      release_type: value_or_nil(params[:release_type])
    )
  end

  folder.link_to_release!(release)

  return {result: 'ok'}.to_json
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

