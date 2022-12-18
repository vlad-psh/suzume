require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'rack/contrib'

require 'yaml'
require 'blueprinter'
require 'fileutils'
require 'id3tag'
require 'open-uri'
require 'tempfile'
require 'securerandom'
require 'mini_magick'
require 'mediainfo-native'
require 'shellwords'

paths browser: '/',
    autocomplete_artist: '/autocomplete/artist',
    autocomplete_release: '/autocomplete/artist/:artist_id/release'

require_relative './helpers.rb'
also_reload './helpers.rb'

%w[models controllers serializers services].each do |dir|
  Dir.glob("./#{dir}/*.rb").each { |f| require_relative f }
  also_reload "./#{dir}/*.rb"
end

helpers TulipHelpers

configure do
  $config = YAML.load(File.open('config/application.yml'))

  use Rack::JSONBodyParser
  use Rack::Session::Cookie,
#        key: 'fcs.app',
#        domain: '172.16.0.11',
#        path: '/',
        expire_after: 2592000, # 30 days
        secret: $config['secret']

  $library_path = $config['library_path']
  $abyss_path = $config['abyss_path']
end

MIME_EXT = {"JPEG" => "jpg", "image/jpeg" => "jpg", "PNG" => "png", "image/png" => "png"}

get :autocomplete_artist do
  q = "%#{params[:term]}%"
  artists = Artist.where('title ILIKE ? OR romaji ILIKE ? OR aliases ILIKE ?', q, q, q)
  artists.map{|p| {id: p.id, value: p.title, romaji: p.romaji, aliases: p.aliases} }.to_json
end

get :autocomplete_release do
#  artist = Artist.find(params[:artist_id])
  q = "%#{params[:term]}%"
  releases = Release.where(artist_id: params[:artist_id])
            .where('title ILIKE ? OR romaji ILIKE ?', q, q)
            .order(title: :asc)
  releases.map{|r| {id: r.id, value: r.title, romaji: r.romaji, year: r.year, rtype: r.release_type}}.to_json
end
