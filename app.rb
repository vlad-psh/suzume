require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
require 'musicbrainz'
require 'lastfm'

require_relative './models.rb'
require_relative './helpers.rb'

also_reload './models.rb'
also_reload './helpers.rb'

paths index: '/',
    artists: '/artists',
    artist: '/artist/:id',
    artist_add_tag: '/artist/tag/add',
    artist_remove_tag: '/artist/tag/remove',
    albums: '/albums',
    album: '/album/:id',
    album_form: '/album_form/:id',
    album_line: '/album_line/:id',
    album_add_tag: '/album/tag/add',
    album_remove_tag: '/album/tag/remove',
    album_cover: '/album_cover/:id',
    lastfm_tags: '/lastfm/artist/:id',
    search: '/search',
    search_by_tag: '/tag/:id',
    tags_index: '/tags'

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
  MusicBrainz.configure do |c|
    c.app_name = $config['app_name']
    c.app_version = $config['app_version']
    c.contact = $config['app_contact']
  end
  $lastfm = Lastfm.new($config["lastfm_api_key"], $config["lastfm_secret"])

  use Rack::Flash
end

def get_tulip_id(dir)
  tulip_files = Dir.glob(File.expand_path("*.tulip", dir))
  tulip_match = tulip_files.count > 0 ? tulip_files[0].match(/.*\/(?<tulip_id>[0-9]*)\.tulip/) : nil
  tulip_id = tulip_match ? tulip_match[:tulip_id] : nil
  return tulip_id
end

get :index do
  @artists = Artist.includes(:tags).all

  request.accept.each do |type|
    if type.to_s == 'text/json'
      halt @artists.to_json(only: [:id, :title, :romaji])
    end
  end

  db_artists = Artist.all.pluck(:filename)
  db_artists << "." << ".."

  @new_artists = []
  Dir.entries($library_path).each do |dir|
    next if db_artists.include?(dir)

## TODO: do I really need this?
#    artist_dir = File.expand_path(dir, $library_path)
#    tulip_id = get_tulip_id(artist_dir)
    @new_artists << dir # unless tulip_id
  end

  slim :index
end

post :artists do
  a = Artist.create(filename: params[:filename],
                       title: params[:filename])
  redirect path_to(:artist).with(a.id)
end

get :search_by_tag do
  tag = Tag.find(params[:id].to_i)

  unless tag
    flash[:error] = "Tag with ID=#{params[:id]} was not found"
    redirect_to :index
  end

  @artists = tag.artists
  @albums = tag.albums
  slim :index
end

def sort_types(a, b)
  priority = ["Album", "EP", "Single"]
  if priority.include?(a)
    if priority.include?(b)
      return priority.index(a) < priority.index(b) ? -1 : 1
    else
      return -1
    end
  elsif priority.include?(b)
    return 1
  else
    return 0
  end
end

def albums_by_type(all_albums)
  albums = {}

  all_albums.each do |a|
    albums[a.primary_type] ||= []
    albums[a.primary_type] << a
  end

  keys = albums.keys.sort{|a,b|sort_types(a, b)}

  result = []
  keys.each {|k| result << {type: k, content: albums[k]} }
  return result
end

get :artist do
  @artist = Artist.includes(:tags).find(params[:id])

  request.accept.each do |type|
    if type.to_s == 'text/json'
      all_albums = @artist.albums.order(date: :desc).where(is_mock: false)
      sorted_albums = albums_by_type(all_albums)
      halt sorted_albums.to_json #(only: [:type, content: {only: :id]])
    end
  end

  all_albums = @artist.albums.order(year: :desc) # is_mock: :asc
  @sorted_albums = albums_by_type(all_albums)

  @new_albums = []
  artist_dir = File.expand_path(@artist.filename, $library_path)
  Dir.entries(artist_dir).each do |dir|
    next if [".", ".."].include?(dir)
    next if all_albums.any? { |a| a.filename == dir }
    @new_albums << dir if File.directory?(File.expand_path(dir, artist_dir))
  end

  slim :artist
end

post :artist do
  a = Artist.find(params[:id].to_i)
  a.title = params[:title]
  a.romaji = params[:romaji]
  a.save

  redirect path_to(:artist).with(a.id)
end

get :album_form do
  @album = Album.find(params[:id].to_i)

  slim :album_form, layout: false
end

get :album_line do
  album = Album.find(params[:id].to_i)
  slim :album_line, layout: false, locals: {album: album}
end

post :album do
  album = Album.find(params[:id].to_i)
  album.year = params[:year].to_i
  album.primary_type = params[:type]
  album.title = params[:title]
  album.romaji = params[:romaji].empty? ? nil : params[:romaji]
  album.save

#  redirect path_to(:artist).with(album.artists.first.id)
  slim :album_line, layout: false, locals: {album: album}
end

post :albums do
  artist = Artist.find(params[:artist_id].to_i)
  album = Album.find_or_initialize_by(filename: params[:filename])
  album.year = params[:year].to_i || nil
  album.title = params[:title]
  album.romaji = params[:romaji].empty? ? nil : params[:romaji]
  album.primary_type = params[:type]
  album.save

  artist.albums << album

  redirect path_to(:artist).with(artist.id)
end

post :artist_add_tag do
  artist = Artist.find(params[:artist_id].to_i)

  t = params[:tag]
  tag_category, tag_name = t.downcase.split(":")
  unless tag_category.length != 1
    tag = Tag.find_or_create_by(category: tag_category.strip, title: tag_name.strip)
    artist.tags << tag
  end

  redirect path_to(:artist).with(artist.id)
end

post :artist_remove_tag do
  artist = Artist.find(params[:artist_id].to_i)
  tag = Tag.find(params[:tag_id].to_i)
  artist.tags.delete(tag)

  return "OK"
end

post :album_add_tag do
  album = Album.find(params[:album_id].to_i)

  t = params[:tag]
  tag_category, tag_name = t.downcase.split(":")
  unless tag_category.length != 1
    tag = Tag.find_or_create_by(category: tag_category.strip, title: tag_name.strip)
    album.tags << tag
  end

  redirect path_to(:artist).with(album.artists.first.id)
end

post :album_remove_tag do
  album = Album.find(params[:album_id].to_i)
  tag = Tag.find(params[:tag_id].to_i)
  album.tags.delete(tag)

  return "OK"
end

get :album_cover do
  album = Album.find(params[:id].to_i)
  artist = album.artists.first
  artist_path = File.expand_path(artist.filename, $library_path)
  album_path = File.expand_path(album.filename, artist_path)
  cover_path = File.expand_path("cover.jpg", album_path)
  if File.exist?(cover_path)
    send_file(cover_path)
  else
    halt 404
  end
end

get :lastfm_tags do
  artist = Artist.find(params[:id].to_i)
  tags = $lastfm.artist.get_top_tags(artist: artist.title)
  slim :tags, layout: false, locals: {tags_array: tags, submit_path: ''}
end

get :search do
  q = params[:query]
  @artists = Artist.where('title ILIKE ?', "%#{q}%")
  @albums = Album.where('title ILIKE ?', "%#{q}%")

  slim :index
end

get :tags_index do
  @tags = Tag.all.order(category: :asc, title: :asc)

  slim :tags_index, locals: {tags: @tags}
end
