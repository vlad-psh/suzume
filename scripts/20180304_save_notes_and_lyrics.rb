# This scripts saves all lyrics and tracks found
# in 'track' records to corresponding 'record' records
# IMPORTANT: all track records will be removed after that!

while tracks = Track.order(id: :asc).limit(100)
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
