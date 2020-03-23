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

paths browser: '/',
    autocomplete_performer: '/autocomplete/performer',
    autocomplete_release: '/autocomplete/performer/:performer_id/release'

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

get :browser do
  protect!

  slim :browser
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

