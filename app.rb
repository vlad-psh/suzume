require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'

require_relative './models.rb'

also_reload './models.rb'

paths index: '/',
    new_artists: '/artists/new',
    artist: '/artist/:id',
    artist_set_discogs_id: '/artist/set-discogs-id',
    album_set_discogs_id: '/album/set-discogs-id'

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

  use Rack::Flash
end

def get_tulip_id(dir)
  tulip_files = Dir.glob(File.expand_path("*.tulip", dir))
  tulip_match = tulip_files.count > 0 ? tulip_files[0].match(/.*\/(?<tulip_id>[0-9]*)\.tulip/) : nil
  tulip_id = tulip_match ? tulip_match[:tulip_id] : nil
  return tulip_id
end

get :index do
  @artists = Artist.all
  slim :index
end

get :new_artists do
  db_artists = Artist.all.pluck(:filename)
  db_artists << "." << ".."

  @artists = []
  Dir.entries($library_path).each do |dir|
    next if db_artists.include?(dir)

    artist_dir = File.expand_path(dir, $library_path)
    tulip_id = get_tulip_id(artist_dir)
    @artists << dir unless tulip_id
  end

  slim :new_artists
end

get :artist do
  @artist = Artist.find(params[:id])
  @albums = @artist.albums

  @new_albums = []
  artist_dir = File.expand_path(@artist.filename, $library_path)
  Dir.entries(artist_dir).each do |dir|
    next if [".", ".."].include?(dir)
    next if @albums.any? { |a| a.filename == dir }
    @new_albums << dir
  end

  slim :artist
end

post :artist_set_discogs_id do
  a = Artist.find_or_create_by(filename: params[:filename])
  a.discogs_id = params[:discogs_id].gsub(/[^0-9]/, '').to_i
  a.title = params[:filename]
  a.save

  redirect path_to(:artist).with(a.id)
end

post :album_set_discogs_id do
  a = Album.find_or_create_by(filename: params[:filename])
  a.discogs_id = params[:discogs_id].gsub(/[^0-9]/, '').to_i
  a.title = params[:filename]
  a.save

  artist = Artist.find(params[:artist_id].to_i)
  artist.albums << a

  redirect path_to(:artist).with(artist.id)
end
