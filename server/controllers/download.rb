paths \
  download_audio: '/download/audio/:uid',
  download_image: '/download/image/:release_id/:cover_type',
  download_abyss: '/download/abyss/:folder_id/:filename',
  download_waveform: '/download/waveform/:uid'

get :download_audio do
  track = Track.find_by(uid: params[:uid])
  halt 404, "Track not found" if track.blank?
  headers['X-Accel-Redirect'] = track.exists_in_library? \
    ? File.join("/nginx-download", track.directory, track.filename) \
    : File.join("/nginx-abyss", track.folder.path, track.original_filename)
  headers['Content-Disposition'] = "inline; filename=\"#{track.original_filename}\""
  headers['Content-Type'] = get_mime(track.original_filename)
end

get :download_image do
  uid = params[:release_id].gsub(/[^a-z0-9]/, '')
  halt 400 unless uid.length == 8
  halt 400 unless %w(cover thumb).include?(params[:cover_type])

  dir = File.join($library_path, uid[0..1], uid[2..])
  cover = Dir.glob(File.join(dir, params[:cover_type] + '.*')).first

  halt 404, "Image not found" if cover.blank?
  image_filename = File.basename(cover)

  headers['X-Accel-Redirect'] = File.join("/nginx-download", uid[0..1], uid[2..], image_filename)
  headers['Content-Disposition'] = "inline; filename=\"#{image_filename}\""
  headers['Content-Type'] = get_mime(image_filename)
end

get :download_abyss do
  protect!

  folder = Folder.find_by(id: params[:folder_id])
  halt 404, "Folder not found" if folder.blank?
  halt 404, "File not found" unless folder.contains_file?(params[:filename])

  headers['X-Accel-Redirect'] = File.join("/nginx-abyss", folder.path, params[:filename])
  headers['Content-Disposition'] = "inline; filename=\"#{params[:filename]}\""
  headers['Content-Type'] = get_mime(File.join(folder.full_path, params[:filename]))
end

get :download_waveform do
  protect!

  return Track.find_by(uid: params[:uid])&.waveform.to_json
end
