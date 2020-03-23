paths \
  index: '/index',
  performer: '/performer/:id',
  year: '/year/:year',
  record: '/record/:id', # PATCH (update some properties)
  search: '/search',
  notes: '/notes',
  lyrics: '/lyrics',
  hide_notes: '/notes/hide'

get :index do
  protect!

  @performers = Performer.all.order(title: :asc)

#  request.accept.each do |type|
#    if type.to_s == 'text/json'
#      halt @artists.to_json(only: [:id, :title, :romaji])
#    end
#  end

  slim :performers
end

get :performer do
  protect!

  @performer = Performer.find(params[:id])
  slim :performer
end

get :year do
  releases = Release.includes(:records).where(year: params[:year]).order(id: :asc)
  @sorted_records = {}
  releases.each {|r| @sorted_records[r] = r.records}

  slim :releases
end

get :search do
  protect!

  q = "%#{params[:query]}%"
  @artists = Artist.where('title ILIKE ? OR romaji ILIKE ? OR aliases ILIKE ?', q, q, q)
  all_albums = Album.where('title ILIKE ? OR romaji ILIKE ?', q, q).order(year: :desc)
  @sorted_albums = albums_by_type(all_albums)

  if all_albums.count == 0 && @artists.count == 1
    redirect path_to(:artist).with(@artists[0].id)
  else
    @title = "#{params[:query]} - Search"
    slim :index
  end
end

post :hide_notes do
  protect!

  if params["hide-notes"] && params["hide-notes"] == "true"
    request.session["hide-notes"] = true
    return 200, '{"hide-notes": true}'
  else
    request.session["hide-notes"] = false
    return 200, '{"hide-notes": false}'
  end
end

post :notes do
  protect!

  parent = case params[:parent_type]
    when 'performer'
      Performer.find(params[:parent_id])
    when 'release'
      Release.find(params[:parent_id])
    when 'record'
      Record.find(params[:parent_id])
    else
      raise StandardError.new("Unknown type: #{params[:parent_type]}")
    end

  parent.notes ||= []
  note = {'c' => params[:content], 'd' => DateTime.now}
  parent.notes << note
  parent.save

  slim :note_item, layout: false, locals: {note: note}
end

post :lyrics do
  protect!

  track = Track.find(params[:track_id])
  halt(500, "Track #{params[:track_id]} not found") unless track

  l = track.lyrics
  l[params[:title]] = params[:content]
  track.lyrics = l
  track.save

  slim :lyrics_item, layout: false, locals: {title: params[:title], lyrics: params[:content]}
end

def get_object_or_error(type, id)
  if type == :record
    object = Record.find_by(id: id)
  else
    throw StandardError.new("Unknown object type: #{type}")
  end

  if object.present?
    return object
  else
    halt 404, "#{type.to_s.capitalize} with id #{id} was not found"
  end
end

patch :record do
  record = get_object_or_error(:record, params['id'])
  if params[:rating].present? && (rating = params[:rating].to_i) >= 0 && rating <= 3
    record.update_attribute(:rating, rating)
    return {emoji: RATING_EMOJI[rating + 1]}.to_json
  end
  return {error: 'Unknown params'}.to_json
end

