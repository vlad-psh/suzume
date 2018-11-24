require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
require 'lastfm'
require 'fileutils'
require 'id3tag'
require 'open-uri'
require 'tempfile'
require 'securerandom'
require 'redcloth'
require 'mini_magick'
require 'mediainfo-native'
require 'shellwords'

paths index: '/',
    performer: '/performer/:id',
    autocomplete_performer: '/autocomplete/performer',
    autocomplete_release: '/autocomplete/performer/:performer_id/release',
    record: '/record/:id', # PATCH (update some properties)

    search: '/search',

    notes: '/notes',
    lyrics: '/lyrics',
    hide_notes: '/notes/hide',
# ----------- auth.rb
    login: '/login',
    logout: '/logout',
# ----------- tag.rb
    tags: '/tags', # index
    tag: '/tag/:id', # delete tag
    tag_add: '/tag/add',
    tag_remove: '/tag/remove',
    search_by_tag: '/tag/:id',
# ----------- api.rb
    api_index: '/api/index',
    api_artist: '/api/artist/:id',
    api_album: '/api/album/:id',
    # these methods are here for compatibility and should be rewritten
    api_cover_orig: '/cover/orig/:id',
    api_cover_thumb: '/cover/thumb/:id',
    api_download_track: '/download/:id',
# ----------- abyss.rb
    abyss_folder: '/abyss/:id', # get, delete
    abyss_process_folder: '/abyss/:folder_id/process', # post
    abyss_set_folder_info: '/abyss/:folder_id/info', # post

    abyss_file: '/abyss/:folder_id/file/:md5', # get (download file), patch (set rating, ...?)
    abyss_set_cover: '/abyss/:folder_id/set_cover/:md5', # post
    abyss_extract_cover: '/abyss/:folder_id/extract_cover/:md5', # post
    abyss_mediainfo: '/abyss/:folder_id/mediainfo/:md5', # get

    download_cover: '/download_cover' # post

require_relative './helpers.rb'
also_reload './helpers.rb'

Dir.glob('./models/*.rb').each {|f| require_relative f}
Dir.glob('./controllers/*.rb').each {|f| require_relative f}
also_reload './models/*.rb'
also_reload './controllers/*.rb'

helpers TulipHelpers

configure do
  puts '---> init <---'

  $config = YAML.load(File.open('config/application.yml'))

  use Rack::Session::Cookie,
#        key: 'fcs.app',
#        domain: '172.16.0.11',
#        path: '/',
        expire_after: 2592000, # 30 days
        secret: $config['secret']

  $library_path = $config['library_path']
  $abyss_path = $config['abyss_path']
  $lastfm = Lastfm.new($config["lastfm_api_key"], $config["lastfm_secret"])

  use Rack::Flash
end

MIME_EXT = {"JPEG" => "jpg", "image/jpeg" => "jpg", "PNG" => "png", "image/png" => "png"}
#RATING_EMOJI = %w(&#x274c; &#x1f342; &#x1f331; &#x1f33b; &#x1f337;) # plants sunflower tulip
RATING_EMOJI = %w(&#x274c; &#x2753; &#x1f3b5; &#x2b50; &#x1f496;) # question note star heart

def get_tulip_id(dir)
  tulip_files = Dir.glob(File.expand_path("*.tulip", dir))
  tulip_match = tulip_files.count > 0 ? tulip_files[0].match(/.*\/(?<tulip_id>[0-9]*)\.tulip/) : nil
  tulip_id = tulip_match ? tulip_match[:tulip_id] : nil
  return tulip_id
end

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

get :autocomplete_performer do
  q = "%#{params[:term]}%"
  performers = Performer.where('title ILIKE ? OR romaji ILIKE ? OR aliases ILIKE ?', q, q, q)
  performers.map{|p| {id: p.id, value: p.title, romaji: p.romaji, aliases: p.aliases} }.to_json
end

get :autocomplete_release do
#  performer = Performer.find(params[:performer_id])
  q = "%#{params[:term]}%"
  releases = Release.where(performer_id: params[:performer_id])
            .where('title ILIKE ? OR romaji ILIKE ?', q, q)
            .order(title: :asc)
  releases.map{|r| {id: r.id, value: r.title, romaji: r.romaji, year: r.year, rtype: r.release_type}}.to_json
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

