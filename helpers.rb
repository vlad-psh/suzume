module TulipHelpers
  def mb_artist_search_path(artist)
    return '' if artist == nil
    return "https://musicbrainz.org/search?query=#{artist.gsub(/[&?=]/, '')}&type=artist&method=indexed"
  end

  def make_release(album)
    artist = album.artists.first
    
    performer = Performer.find_or_initialize_by(old_id: artist.id)
    performer.update_attributes(
      title: artist.title,
      aliases: "#{artist.romaji}, #{artist.aliases}",
      tmp_tags: artist.tagsstr
    )

    release = Release.find_or_initialize_by(old_id: album.id)    
    release.update_attributes(
      performer: performer,
      title: "#{album.year} #{album.title}",
      aliases: album.romaji,
      tmp_tags: album.tagsstr,
      old_id: album.id
    )
    # TODO: move cover/write property/etc

    # Following should be executed after 'release' object will get ID
    release.update_attributes(
      directory: File.join(Date.today.strftime("%Y%m"), release.id.to_s)
    )

    return release
  end

  def make_record(release, t) # t for track
    yearmonth = Date.today.strftime("%Y%m")
    ympath = File.join($library_path, "lib", yearmonth)
    release_path = File.join(ympath, release.id.to_s)

    if t.rating >= 7
      Dir.mkdir(ympath) unless Dir.exist?(ympath)
      Dir.mkdir(release_path) unless Dir.exist?(release_path)
      extension = t.filename.downcase.gsub(/.*\.([^\.]*)/, "\\1")
      # create unique newfilename
      while File.exist?(File.join(release_path, newfilename = "#{SecureRandom.hex(4)}.#{extension}")) do end

      if extension == 'mp3'
        `id3 -2 -rAPIC -rGEOB -s 0 -R '#{t.full_path}'`
      elsif extension == 'm4a'
        `mp4art --remove '#{t.full_path}'`
        `mp4file --optimize '#{t.full_path}'`
      end

      FileUtils.move(t.full_path, File.join(release_path, newfilename))
  
      record = Record.create(
        release: release,
        original_filename: t.filename,
        filename: newfilename,
        directory: File.join(yearmonth, release.id.to_s),
        rating: (t.rating - 7),
        lyrics: t.lyrics,
        tmp_tags: t.tagsstr,
        old_id: t.id
      )
      record.update_mediainfo!
    else
      File.delete(t.full_path) rescue nil
    end

    t.status = "processed"
    t.save
  end

  def process_album(album)
    release = make_release(album)
    album.tracks.where.not(status: "processed").each do |t|
      make_record(release, t)
    end
    if release.full_path && album.cover_path # also checks for existence of new path
      cover_ext = album.cover_path.gsub(/.*\./, '')
      FileUtils.move(album.cover_path, File.expand_path("cover.#{cover_ext}", release.full_path))
      FileUtils.move(album.thumb_path, File.expand_path("thumb.#{cover_ext}", release.full_path))
    end

    album.status = "processed"
    album.save
    # Dir.delete(album.full_path)
  end

#  def process_track(track)
#    release = make_release(track.album)
#    record = make_record(release, track)
#  end

  def ms2ts(time)
    ms   = time % 1000
    time = time / 1000
    s    = time % 60
    time = time / 60
    m    = time % 60
    time = time / 60
    h    = time
    msblock = "<span class='msec'>.#{ms/100}</span>"
    if h != 0
      return "#{h}:#{'%02d' % m}:#{'%02d' % s}#{msblock}"
    elsif m != 0
      return "#{m}:#{'%02d' % s}#{msblock}"
    else
      return "0:#{'%02d' % s}#{msblock}"
    end
  end

  def mediainfo(info)
    return nil unless info

    duration = "<span class='duration'>#{ms2ts(info['dur'])}</span>"

    br_limit = info['brm'] == 'CBR' ? 256 : 220 # Highlight if less than 256CBR or 220VBR
    br_value = info['br'].to_i/1000
    bitrate = "<span class='bitrate #{br_value < br_limit ? 'attention': nil}'>#{br_value}#{info['brm']}</span>"

    sr_value = (info['sr'].to_i/1000.0).round(3)
    samplerate = "<span class='samplerate' #{sr_value < 44.1 ? 'attention' : nil}>#{sr_value}kHz</span>"

    return "<span class='mediainfo'>#{duration} | #{bitrate} @ #{samplerate}</span>"
  end

  def strip_filename(fln)
    return fln.gsub(/\.mp3$/i, '').gsub(/\.m4a$/i, '').gsub(/^[0-9\-\.]* (- )?/, '')
  end

  def admin?
    session['role'] == 'admin'
  end

  def guest?
    session['role'] == 'guest'
  end

  def protect!
    return if admin?
    halt 401, "Unauthorized"
  end

  def hide!
    return if admin? || guest?
    halt 401, "Unauthorized"
  end
end
