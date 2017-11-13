require './app.rb'

album = Album.find()) # syntax error was made intentionally
artist = album.artists.first

performer = Performer.find_or_initialize_by(old_id: artist.id)
performer.update_attributes(
  title: artist.title,
  aliases: "#{artist.romaji}, #{artist.aliases}",
  tmp_tags: artist.tags.map{|t|"#{t.category}:#{t.title}"}.join(", ")
)

release = Release.create(
  performer: performer,
  title: "#{album.year} #{album.title}",
  aliases: album.romaji,
  tmp_tags: album.tags.map{|t|"#{t.category}:#{t.title}"}.join(", "),
  old_id: album.id
)
# TODO: move cover/write property/etc

yearmonth = Date.today.strftime("%Y%m")
ympath = File.join($library_path, "lib", yearmonth)
release_path = File.join(ympath, release.id.to_s)
album.tracks.where(is_processed: false).each do |t|
  if t.rating >= 7
    Dir.mkdir(ympath) unless Dir.exist?(ympath)
    Dir.mkdir(release_path) unless Dir.exist?(release_path)
    extension = t.filename.downcase.gsub(/.*\.([^\.]*)/, "\\1")
    # create unique newfilename
    while File.exist?(File.join(release_path, newfilename = "#{SecureRandom.hex(4)}.#{extension}")) do end
    File.rename(t.full_path, File.join(release_path, newfilename))

    record = Record.create(
      release: release,
      original_filename: t.filename,
      filename: newfilename,
      directory: File.join(yearmonth, release.id.to_s),
      rating: (t.rating - 7),
      lyrics: t.lyrics,
      tmp_tags: t.tags.map{|t|"#{t.category}:#{t.title}"}.join(", "),
      old_id: t.id
    )
  else
    File.delete(t.full_path)
  end
  t.is_processed = true
  t.save
end
album.is_processed = true
album.save
# Dir.delete(album.full_path)
