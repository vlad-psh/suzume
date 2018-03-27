get :folder do
  @folder = Folder.find_by(id: params[:id]) || Folder.root

  slim :folder
end

get :download_file do
  folder = Folder.find(params[:folder_id])
  file_path = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless file_path
  file_fullpath = File.join(folder.full_path, file_path)
  send_file file_fullpath
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
    release_type: value_or_nil(params[:release_type])
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

  redirect path_to(:folder).with(folder.id)
end

post :abyss_set_rating do
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename
  folder.files[params[:md5]]['rating'] = params[:rating].to_i
  folder.save if folder.changed?

  return 'ok'
end

