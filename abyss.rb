get :abyss_folder do
  @folder = Folder.find_by(id: params[:id]) || Folder.root

  slim :folder
end

delete :abyss_folder do
  folder = Folder.find(params[:id])
  throw StandardError.new("Already removed") if folder.is_removed
  FileUtils.remove_dir(folder.full_path)
  folder.update_attributes(is_removed: true)

  flash[:notice] = "Folder \"#{folder.path}\" was removed"

  redirect path_to(:abyss_folder).with(folder.folder_id)
end

get :abyss_file do
  folder = Folder.find(params[:folder_id])
  file_path = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless file_path
  file_fullpath = File.join(folder.full_path, file_path)
  send_file file_fullpath
end

patch :abyss_file do # currently only rating update
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename
  folder.files[params[:md5]]['rating'] = params[:rating].to_i
  folder.save if folder.changed?

  return folder.files[params[:md5]].to_json
end

def value_or_nil(v)
  return v.blank? ? nil : v
end

post :process_folder do
  folder = Folder.find(params[:id])
  throw StandardError.new("Already processed") if folder.is_processed

  performer = Performer.find(params[:performer_id]) if params[:performer_id].present?
  unless performer.present?
    throw StandardError.new("Performer title cannot be blank") if params[:performer_title].blank?
    performer = Performer.create(
        title: params[:performer_title],
        romaji: value_or_nil(params[:performer_romaji]),
        aliases: value_or_nil(params[:performer_aliases])
    )
  end

  throw StandardError.new("Release title cannot be blank") if params[:release_title].blank?
  # TODO: if title is empty, append tracks to 'no album'
  release = Release.create(
    performer: performer,
    title: params[:release_title],
    year: value_or_nil(params[:release_year]),
    romaji: value_or_nil(params[:release_romaji]),
    release_type: value_or_nil(params[:release_type]),
    notes: folder.notes.present? ? folder.notes : nil
  )

  release.update_attributes(
      directory: File.join(Date.today.strftime("%Y%m"), release.id.to_s)
    )

  folder.files.each do |md5,details|
    if details['type'] == 'audio' && details['rating'].present? && details['rating'] >= 0
      FileUtils.mkdir_p(release.full_path) unless Dir.exist?(release.full_path)
      # create unique newfilename
      extension = details['fln'].downcase.gsub(/.*\.([^\.]*)/, "\\1")
      while File.exist?(File.join(release.full_path, newfilename = "#{SecureRandom.hex(4)}.#{extension}")) do end

      oldfilepath = File.join(folder.full_path, details['fln'])
      newfilepath = File.join(release.full_path, newfilename)
      FileUtils.copy(oldfilepath, newfilepath)

      if extension == 'mp3'
        `id3 -2 -rAPIC -rGEOB -s 0 -R '#{newfilepath}'`
      elsif extension == 'm4a'
        `mp4art --remove '#{newfilepath}'`
        `mp4file --optimize '#{newfilepath}'`
      end

      record = Record.create(
        release: release,
        original_filename: details['fln'],
        filename: newfilename,
        directory: File.join(Date.today.strftime("%Y%m"), release.id.to_s),
        rating: details['rating']
      )
      record.update_mediainfo!
    end
  end

  folder.files.each do |md5,details|
    if details['type'] == 'image' && details.has_key?('cover') && details['cover'] == true
      FileUtils.mkdir_p(release.full_path) unless Dir.exist?(release.full_path)

      oldfilepath = File.join(folder.full_path, details['fln'])
      extension = details['fln'].downcase.gsub(/.*\.([^\.]*)/, "\\1")
      newfilepath = File.join(release.full_path, "cover.#{extension}")
      thumbfilepath = File.join(release.full_path, "thumb.#{extension}")
      FileUtils.copy(oldfilepath, newfilepath)

      img = MiniMagick::Image.open(newfilepath)
      if [img.width, img.height].max > 400
        img.resize("400x400>")
        img.write(thumbfilepath)
      else
        FileUtils.copy(newfilepath, thumbfilepath)
      end
      img.destroy! # remove temp file
    end
  end if release.records.count > 0

  folder.update_attributes(is_processed: true)

  flash[:notice] = "Folder \"#{folder.path}\" processed successfully"

  redirect path_to(:abyss_folder).with(folder.id)
end

post :abyss_set_cover do
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename

  folder.files.each do |md5,details|
    # clear cover status for all images
    details.delete('cover') if details['type'] == 'image'
  end

  folder.files[params[:md5]]['cover'] = true
  folder.save if folder.changed?

  return 'ok'
end

post :abyss_extract_cover do
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
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename

  cmd = "mediainfo %s" % Shellwords.escape(File.join(folder.full_path, filename))
  return `#{cmd}`
end

post :download_cover do
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
