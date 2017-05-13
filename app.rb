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

also_reload './models.rb'

paths index: '/',
    new_artists: '/artists/new',
    artist: '/artist/:id',
    album: '/album/:id',
    album_form: '/album_form/:id',
    album_cell: '/album_cell/:id',
    artist_set_mbid: '/mbid/artists',
    album_set_mbid: '/mbid/albums',
    artist_tags: '/tag/artist/:id',
    album_tags: '/tag/album/:id',
    artists_by_tag: '/artists/tag/:id',
    lastfm_tags: '/lastfm/artist/:id'

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

def update_artist_albums(artist)
  artist_albums = artist.albums
  mb_artist = MusicBrainz::Artist.find(artist.mbid, inc: nil)
  offset = 0
  step = 100
  loop do
    artist_releases = mb_artist.release_groups(offset: offset, limit: step, inc: nil)

    3.times do |i|
      if artist_releases == nil || artist_releases.count == 0
        sleep 2
        artist_releases = mb_artist.release_groups(offset: offset, limit: step, inc: nil)
      end
    end
    break if artist_releases == nil || artist_releases.count == 0

    artist_releases.each do |r|
      album = Album.find_or_initialize_by(mbid: r.id)
      album.update_attributes(
        date: r.first_release_date,
        title: r.title,
        primary_type: r.primary_type,
        secondary_type: r.secondary_types.join(" + ")
      )
      album.save
      artist.albums << album unless artist_albums.include?(album)
    end

    break if artist_releases.total_count < artist_releases.offset + step # latest page
    offset += step
  end
end

get :index do
  @artists = Artist.all
  @tags = Tag.all.order(category: :asc, title: :asc)

  request.accept.each do |type|
    if type.to_s == 'text/json'
      halt @artists.to_json(only: [:id, :title, :romaji])
    end
  end

  slim :index
end

get :artists_by_tag do
  tag = Tag.find(params[:id].to_i)

  unless tag
    flash[:error] = "Tag with ID=#{params[:id]} was not found"
    redirect_to :index
  end

  @artists = tag.artists
  @tags = Tag.all.order(category: :asc, title: :asc)
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

def albums_by_type(all_albums)
  albums = {}

  all_albums.each do |a|
    albums[a.both_types] ||= []
    albums[a.both_types] << a
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

  all_albums = @artist.albums.order(date: :desc) # is_mock: :asc
  @sorted_albums = albums_by_type(all_albums)

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

get :album_form do
  @album = Album.find(params[:id].to_i)

  slim :album_form, layout: false
end

post :album_form do
  @album = Album.find(params[:id].to_i)
  @album.title = params[:title]
  @album.romaji = params[:romaji] && !params[:romaji].empty? ? params[:romaji] : nil
  @album.save

  slim :album_cell, layout: false
end

get :album_cell do
  @album = Album.find(params[:id].to_i)

  slim :album_cell, layout: false
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

post :artist_tags do
  artist = Artist.find(params[:id].to_i)

  tags = params[:tags].split(",")
  tags.each do |t|
    tag_category, tag_name = t.downcase.split(":")
    next if tag_category.length > 1
    tag = Tag.find_or_create_by(category: tag_category.strip, title: tag_name.strip)
    artist.tags << tag
  end

  redirect path_to(:artist).with(artist.id)
end

get :lastfm_tags do
  artist = Artist.find(params[:id].to_i)
  @tags = $lastfm.artist.get_top_tags(artist: artist.title)
  slim :tags, layout: false
end
