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

    search: '/search',

    notes: '/notes',
    lyrics: '/lyrics',
    hide_notes: '/notes/hide',

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
# ----------- abyss.rb
    folder: '/abyss/:id',
    process_folder: '/abyss_process/:id',
    abyss_remove_folder: '/abyss_remove/:id',
    download_file: '/abyss/:folder_id/:md5',
    download_cover: '/download_cover',
    abyss_set_cover: '/abyss/cover/:folder_id/:md5',
    abyss_extract_cover: '/abyss/extract_cover/:folder_id/:md5',
    abyss_set_rating: '/abyss/rating/:folder_id/:md5',
    abyss_mediainfo: '/abyss/mediainfo/:folder_id/:md5'

%w(models.rb helpers.rb api.rb tag.rb abyss.rb).each do |file|
  require_relative "./#{file}"
  also_reload "./#{file}"
end

helpers TulipHelpers

configure do
  puts '---> init <---'

  $config = YAML.load(File.open('config/application.yml'))

  use Rack::Session::Cookie,
#        key: 'fcs.app',
#        domain: '172.16.0.11',
#        path: '/',
#        expire_after: 2592000,
        secret: $config['secret']

  $library_path = $config['library_path']
  $abyss_path = $config['abyss_path']
  $lastfm = Lastfm.new($config["lastfm_api_key"], $config["lastfm_secret"])

  use Rack::Flash
end

MIME_EXT = {"JPEG" => "jpg", "image/jpeg" => "jpg", "PNG" => "png", "image/png" => "png"}
RATINGS = ['Not Rated', 'Appalling', 'Horrible', 'Very Bad', 'Bad',
           'Average', 'Fine', 'Good', 'Very Good', 'Great', 'Masterpiece']

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
    when 'folder'
      Folder.find(params[:parent_id])
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

get :login do
  if admin? || guest?
    flash[:notice] = "Already logged in"
    redirect path_to(:index)
  else
    slim :login
  end
end

post :login do
  if params['username'].blank? || params['password'].blank?
    flash[:error] = "Incorrect username or password :("
    redirect path_to(:login)
  elsif $config['admins'] && $config['admins'][params['username']] == params['password']
    flash[:notice] = "Successfully logged in as admin!"
    session['role'] = 'admin'
    redirect path_to(:index)
  elsif $config['guests'] && $config['guests'][params['username']] == params['password']
    flash[:notice] = "Successfully logged in as spectator!"
    session['role'] = 'guest'
    redirect path_to(:index)
  else
    flash[:error] = "Incorrect username or password :("
    redirect path_to(:login)
  end
end

delete :logout do
  session.delete('role')
  flash[:notice] = "Successfully logged out"
  redirect path_to(:index)
end

