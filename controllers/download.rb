get :download_audio do
  record = Record.find_by(uid: params[:uid])
  halt 404, "Record not found" if record.blank?
  headers['X-Accel-Redirect'] = File.join("/nginx-download", record.directory, record.filename)
  headers['Content-Disposition'] = "inline; filename=\"#{record.original_filename}\""
  headers['Content-Type'] = get_mime(record.original_filename)
end

get :download_image do
  release = Release.find(params[:release_id])

  halt 404, "Image not found" if release.cover.blank?
  image_filename = "#{params[:cover_type]}.#{release.cover}"

  headers['X-Accel-Redirect'] = File.join("/nginx-download", release.directory, image_filename)
  headers['Content-Disposition'] = "inline; filename=\"#{image_filename}\""
  headers['Content-Type'] = get_mime(image_filename)
end
