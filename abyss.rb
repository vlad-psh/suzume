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

post :abyss_set_rating do
  folder = Folder.find(params[:folder_id])
  filename = folder.files[params[:md5]].try(:[], 'fln')
  throw StandardError.new("Wrong file MD5: #{params[:md5]}") unless filename
  folder.files[params[:md5]]['rating'] = params[:rating].to_i
  folder.save if folder.changed?

  return 'ok'
end

