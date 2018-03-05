require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
#require 'musicbrainz'
require 'lastfm'
require 'fileutils'
require 'id3tag'
require 'open-uri'
require 'tempfile'
require 'securerandom'
require 'redcloth'
require 'mini_magick'
require 'mediainfo-native'

paths index: '/',
    performer: '/performer/:id',

    search: '/search',
    search_by_tag: '/tag/:id',

    tags: '/tags', # index
    tag: '/tag/:id', # delete tag
    tag_add: '/tag/add',
    tag_remove: '/tag/remove',

    hide_notes: '/notes/hide',

    api_index: '/api/index',
    api_artist: '/api/artist/:id',
    api_album: '/api/album/:id',

    notes: '/notes',
    lyrics: '/lyrics',

    login: '/login',
    logout: '/logout'

require_relative './models.rb'
require_relative './helpers.rb'
require_relative './api.rb'

also_reload './models.rb'
also_reload './helpers.rb'
also_reload './api.rb'


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
  $covers_path = $config['covers_path']
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

get :search_by_tag do
  protect!

  tag = Tag.find(params[:id].to_i)

  unless tag
    flash[:error] = "Tag with ID=#{params[:id]} was not found"
    redirect_to :index
  end

  @artists = tag.artists
  @sorted_albums = albums_by_type(tag.albums.order(year: :desc))
  @tracks = tag.tracks
  @notes = {}
  Note.where(parent_type: 't', parent_id: @tracks).each do |n|
    @notes[n.parent_id] ||= []
    @notes[n.parent_id] << n
  end

  slim :index
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

get :tags do
  protect!

  @tags = Tag.all.order(category: :asc, title: :asc)

  slim :tags, locals: {tags: @tags}
end

delete :tag do
  protect!

  tag = Tag.find(params[:id])
  unless tag
    flash[:error] = "Tag not found"
  else
    tag_title = tag.title
    _artists = tag.artists.count
    _albums = tag.albums.count
    _tracks = tag.tracks.count
    unless _artists == 0 && _albums == 0 && _tracks == 0
     flash[:error] = "Tag '#{tag_title}' still has childs. Artists: #{_artists}, albums: #{_albums}, tracks: #{_tracks}"
    else
      tag.destroy
      flash[:notice] = "Tag '#{tag_title}' successfully deleted"
    end
  end

  redirect path_to(:tags)
end

post :tag_add do
  protect!

  performer = Performer.includes(:tags).find(params[:performer_id])

  tag_category, tag_title = params[:tag_name].downcase.split(":")
  unless tag_category.length != 1
    tag = Tag.find_or_create_by(title: tag_title, category: tag_category)
    performer.tags << tag unless performer.tags.include?(tag)
  else
    halt 400, "Specify category!"
  end

  slim :tag_item, layout: false, locals: {tag: tag, performer: performer}
end

post :tag_remove do
  protect!

  TagRelation.where(
        parent_type: params[:obj_type],
        parent_id: params[:obj_id],
        tag_id: params[:tag_id]).each do |tr|
    tr.delete
  end

  return "OK"
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

  n = Note.create(parent_type: params[:parent_type],
        parent_id: params[:parent_id],
        content: params[:content])

  slim :note_item, layout: false, locals: {note: n}
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

