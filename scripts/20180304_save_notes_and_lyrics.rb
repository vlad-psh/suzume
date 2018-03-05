# This scripts saves all lyrics and tracks found
# in 'track' records to corresponding 'record' records
# IMPORTANT: all track records will be removed after that!

while (tracks = Track.order(id: :asc).limit(100)).length > 0
  tracks.each do |t|
    record = Record.find_by(old_id: t.id)

    if record
      record.lyrics = t.lyrics if t.lyrics

      unless t.notes.empty?
        notes = []
        t.notes.each {|n| notes << {c: n.content, d: n.created_at} }
        record.notes = notes
      end

      record.save
    end

    t.destroy!
  end
end; nil

while (albums = Album.order(id: :asc).limit(100)).length > 0
  albums.each do |album|
    release = Release.find_by(old_id: album.id)

    if release
      release.title = album.title
      release.romaji = album.romaji
      release.year = album.year
      release.release_type = album.primary_type

      unless album.notes.empty?
        notes = []
        album.notes.each {|n| notes << {c: n.content, d: n.created_at} }
        release.notes = notes
      end

      release.save
    end

    album.destroy!
  end
end; nil

while (artists = Artist.order(id: :asc).limit(100)).length > 0
  artists.each do |artist|
    perf = Performer.find_by(old_id: artist.id)

    if perf
      perf.title = artist.title
      perf.romaji = artist.romaji
      perf.aliases = artist.aliases

      unless artist.notes.empty?
        notes = []
        artist.notes.each {|n| notes << {c: n.content, d: n.created_at} }
        perf.notes = notes
      end

      perf.save
    end

    artist.destroy!
  end
end; nil


