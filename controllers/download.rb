paths \
  download_audio: '/download/audio/:uid',
  download_image: '/download/image/:release_id/:cover_type'

get :download_audio do
  track = Track.find_by(uid: params[:uid])
  halt 404, "Track not found" if track.blank?
  headers['X-Accel-Redirect'] = track.stored? \
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
