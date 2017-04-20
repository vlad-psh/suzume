require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
require 'musicbrainz'

require_relative './models.rb'

also_reload './models.rb'

paths index: '/',
    new_artists: '/artists/new',
    artist: '/artist/:id',
    artist_set_mbid: '/artist/set-mbid',
    album: '/album/:id',
    album_set_mbid: '/album/set-mbid'

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
    c.query_interval = 0.2
  end

  use Rack::Flash
end

def get_tulip_id(dir)
  tulip_files = Dir.glob(File.expand_path("*.tulip", dir))
  tulip_match = tulip_files.count > 0 ? tulip_files[0].match(/.*\/(?<tulip_id>[0-9]*)\.tulip/) : nil
  tulip_id = tulip_match ? tulip_match[:tulip_id] : nil
  return tulip_id
end

def update_artist_albums(artist)
  artist_albums = artist.albums
  mb_artist = MusicBrainz::Artist.find(artist.mbid)
  offset = 0
  loop do
    artist_releases = mb_artist.release_groups(offset: offset)

    3.times do |i|
      if artist_releases == nil || artist_releases.count == 0
        sleep 2
        artist_releases = mb_artist.release_groups(offset: offset)
      end
    end
    break if artist_releases == nil || artist_releases.count == 0

    artist_releases.each do |r|
      album = Album.find_or_initialize_by(mbid: r.id)
      album.update_attributes(
        date: r.first_release_date,
        title: r.title,
        primary_type: r.type,
        secondary_type: r.subtypes
      )
      album.save
      artist.albums << album unless artist_albums.include?(album)
    end

    break if artist_releases.count < 25 # latest page
    offset += 25
    sleep 1
  end
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

get :artist do
  @artist = Artist.find(params[:id])
  all_albums = @artist.albums.order(date: :desc) # is_mock: :asc

  @albums = {}

  all_albums.each do |a|
    @albums[a.both_types] ||= []
    @albums[a.both_types] << a
  end

  @release_types = @albums.keys.sort{|a,b|sort_types(a, b)}

  @new_albums = []
  artist_dir = File.expand_path(@artist.filename, $library_path)
  Dir.entries(artist_dir).each do |dir|
    next if [".", ".."].include?(dir)
    next if all_albums.any? { |a| a.filename == dir }
    @new_albums << dir if File.directory?(File.expand_path(dir, artist_dir))
  end

  @suggestions = {}
  @new_albums.each do |na|
    matches = {}
    na.downcase.gsub(/[[:punct:]]/, ' ').split.each do |w|
      all_albums.each do |a|
        if a.title.downcase.include?(w)
          matches[a] ||= 0
          matches[a] += 1
        end
      end
    end
    matches.sort_by{|k,v|v}.reverse.each do |match|
      @suggestions[na] ||= {}
      @suggestions[na][match[0]] = match[1]
    end
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

post :artist_set_mbid do
  a = Artist.find_or_create_by(filename: params[:filename])
  a.mbid = params[:mbid]
  a.title = params[:filename]
  a.save

  update_artist_albums(a)

  redirect path_to(:artist).with(a.id)
end

post :album do
  album = Album.find(params[:id].to_i)
  album.title = params[:title]
  album.romaji = params[:romaji]
  album.save

  redirect path_to(:artist).with(album.artists.first.id)
end

post :album_set_mbid do
  a = Album.where(mbid: params[:mbid]).take

  if a != nil
    a.filename = params[:filename]
    a.is_mock = false
    a.save

    flash[:notice] = "Successfully assigned mbid = #{params[:mbid]} to \"#{params[:filename]}\""
  else
    flash[:error] = "Unable to find Album with mbid = #{params[:mbid]}"
  end

  redirect path_to(:artist).with(params[:artist_id].to_i)
end
