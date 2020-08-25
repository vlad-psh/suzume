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
  release = Release.find(params[:release_id])

  halt 404, "Image not found" if release.cover.blank?
  image_filename = "#{params[:cover_type]}.#{release.cover}"

  headers['X-Accel-Redirect'] = File.join("/nginx-download", release.directory, image_filename)
  headers['Content-Disposition'] = "inline; filename=\"#{image_filename}\""
  headers['Content-Type'] = get_mime(image_filename)
end
