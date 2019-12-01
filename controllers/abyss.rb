get :abyss_folder do
  protect!
  @folder = Folder.find_by(id: params[:id]) || Folder.root

  slim :folder
end

delete :abyss_folder do
  protect!
  folder = Folder.find(params[:id])
  throw StandardError.new("Already removed") if folder.is_removed
  FileUtils.remove_dir(folder.full_path)
  folder.update_attributes(is_removed: true)

  flash[:notice] = "Folder \"#{folder.path}\" was removed"

  redirect path_to(:abyss_folder).with(folder.folder_id)
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

patch :abyss_file do # currently only rating update
  protect!
  folder = Folder.find(params[:folder_id])
  if params[:rating].present? && (rating = params[:rating].to_i) >= -1 && rating <= 3
    folder.set_rating(params[:md5], rating)
    folder.update_audio(params[:md5]) if folder.release_id
    return {emoji: RATING_EMOJI[rating + 1]}.to_json
  end
  return {error: 'Unknown params'}.to_json
end

def value_or_nil(v)
  return v.blank? ? nil : v
end

post :abyss_set_folder_info do
  protect!
  folder = Folder.find(params[:folder_id])

  performer = Performer.find(params[:performer_id]) if params[:performer_id].present?
  unless performer.present?
    throw StandardError.new("Performer title cannot be blank") if params[:performer_title].blank?
    performer = Performer.create(
        title: params[:performer_title],
        romaji: value_or_nil(params[:performer_romaji]),
        aliases: value_or_nil(params[:performer_aliases])
    )
  end

  release = Release.find_by(id: params[:release_id]) if params[:release_id].present?
  unless release.present?
    throw StandardError.new("Release title cannot be blank") if params[:release_title].blank?
    # TODO: if title is empty, append tracks to 'no album'

    release = Release.create(
      performer: performer,
      title: params[:release_title],
      year: value_or_nil(params[:release_year]),
      romaji: value_or_nil(params[:release_romaji]),
      format: value_or_nil(params[:release_format]),
      release_type: value_or_nil(params[:release_type])
    )
    release.update_attributes(
        directory: File.join(Date.today.strftime("%Y%m"), release.id.to_s)
      )
  end
  release.update_attribute(:completed, false) if release.completed && !folder.is_processed

  folder.update_attribute(:release_id, release.id)
  folder.process_files!

  redirect path_to(:abyss_folder).with(folder.id)
end

post :abyss_process_folder do
  protect!
  folder = Folder.find(params[:folder_id])
  folder.full_process!
  redirect path_to(:abyss_folder).with(folder.id)
end

post :abyss_set_cover do
  protect!
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename

  folder.files.each do |md5,details|
    # clear cover status for all images
    details.delete('cover') if details['type'] == 'image'
  end

  folder.files[params[:md5]]['cover'] = true
  folder.update_image(params[:md5]) if folder.release.present?
  folder.save if folder.changed?

  return 'ok'
end

post :abyss_extract_cover do
  protect!
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename

  filepath = File.join(folder.full_path, filename)

  iter = 0
  ID3Tag.read(File.open(filepath, "rb")).all_frames_by_id(:APIC).each do |pic|
    if MIME_EXT.include?(pic.mime_type)
      type = MIME_EXT[pic.mime_type]
      cover_filename = "#{DateTime.now.strftime('%Y%m%d_%H%M%S')}_#{iter}.#{type}"

      cover_file = File.open(File.join(folder.full_path, cover_filename), 'w')
      cover_file.write(pic.content)
      cover_file.close

      iter += 1
    end
  end

  redirect path_to(:abyss_folder).with(folder.id)
end

get :abyss_mediainfo do
  protect!
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename

  cmd = "mediainfo %s" % Shellwords.escape(File.join(folder.full_path, filename))
  return `#{cmd}`
end

post :download_cover do
  protect!
  folder = Folder.find(params[:folder_id])

  if params[:url] =~ /redacted\.ch/
    params[:url] = URI.decode(params[:url].gsub(/.*i=/, '').gsub(/&.*/, ''))
  end

  saved_file = Tempfile.new('tulip')
  open(params[:url]) do |read_file|
    saved_file.write(read_file.read)
  end
  saved_file.close

  img = MiniMagick::Image.open(saved_file.path)
  extension = MIME_EXT[img.mime_type] || 'jpg'
  img.destroy!

  newfilepath = File.join(folder.full_path, "#{DateTime.now.strftime('%Y%m%d_%H%M%S')}.#{extension}")
  FileUtils.copy(saved_file.path, newfilepath)
  FileUtils.chmod(0644, newfilepath)

  saved_file.unlink

  redirect path_to(:abyss_folder).with(folder.id)
end
