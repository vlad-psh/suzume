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
    set_discogs_id: '/artist/set-discogs-id'

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
    @artists << dir
  end

  slim :new_artists
end

get :artist do
  @artist = Artist.find(params[:id])
  slim :artist
end

post :set_discogs_id do
  a = Artist.find_or_create_by(filename: params[:artist_name])
  a.discogs_id = params[:discogs_id].gsub(/[^0-9]/, '').to_i
  a.title = params[:artist_name]
  a.save

  redirect path_to(:artist).with(a.id)
end
