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
    performers:  '/performers',
    performer: '/performer/:id',

    process_artist: '/process/artist/:id',
    process_album: '/process/album/:id',
    process_track: '/process/track/:id',

    artists: '/artists',
    artist: '/artist/:id',
    albums: '/albums',
    album: '/album/:id',
    album_form: '/album_form/:id',
    album_line: '/album_line/:id',

    set_album_cover_from_url: '/cover/url/:id',
    album_cover_thumb: '/cover/thumb/:id', # handled by nginx
    album_cover_orig: '/cover/orig/:id',

    search: '/search',
    search_by_tag: '/tag/:id',

    tags: '/tags', # index
    tag: '/tag/:id', # delete tag
    tag_add: '/tag/add',
    tag_remove: '/tag/remove',
    lastfm_tags: '/lastfm/artist/:id',

    track_rating: '/rating/track/:id',
    hide_notes: '/notes/hide',

    api_index: '/api/index',
    api_artist: '/api/artist/:id',
    api_album: '/api/album/:id',

    download: '/download/:id',
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

  @artists = Artist.order(status: :asc, created_at: :desc).all

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

get :performers do
  protect!

  @performers = Performer.all.order(title: :asc)
  slim :performers
end

get :performer do
  protect!

  @performer = Performer.find(params[:id])
  slim :performer
end

post :process_artist do
  protect!

  artist = Artist.find(params[:id])
  if artist.albums.where.not(status: 'processed').count == 0
    artist.status = 'processed'
    artist.save
    flash[:notice] = "#{artist.title} processed successfully"
  else
    flash[:error] = "Unable to 'process' artist: unprocessed albums found"
  end
  redirect path_to(:artist).with(artist.id)
end

post :process_album do
  protect!

  album = Album.find(params[:id])
  process_album(album) if album
  redirect path_to(:artist).with(album.artists.first.id)
end

post :process_track do
  protect!

  track = Track.find(params[:id])
  process_track(track) if track
  redirect path_to(:album).with(track.album.id)
end

post :artists do
  protect!

  a = Artist.create(filename: params[:filename],
                       title: params[:filename])
  redirect path_to(:artist).with(a.id)
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
  protect!

  @artist = Artist.find(params[:id])

  request.accept.each do |type|
    if type.to_s == 'text/json'
      all_albums = @artist.albums.order(date: :desc).where(is_mock: false)
      sorted_albums = albums_by_type(all_albums)
      halt sorted_albums.to_json #(only: [:type, content: {only: :id]])
    end
  end

  all_albums = @artist.albums.order(year: :desc, title: :asc) # is_mock: :asc
  # try to set cover for albums with .has_cover == -1
  all_albums.each do |a|
    if a.has_cover == -1
      a.has_cover = (get_album_cover(a) == 0 ? 0 : 1)
      a.save
    end
  end
  @sorted_albums = albums_by_type(all_albums)

  @new_albums = []
  artist_dir = File.expand_path(@artist.filename, $library_path)
  Dir.entries(artist_dir).each do |dir|
    next if [".", ".."].include?(dir)
    next if all_albums.any? { |a| a.filename == dir }
    @new_albums << dir if File.directory?(File.expand_path(dir, artist_dir))
  end if Dir.exist?(artist_dir)

  @tracks = Track.where(album: all_albums, rating: 7..10).shuffle

  @title = "#{@artist.title}"
  slim :artist
end

post :artist do
  protect!

  a = Artist.find(params[:id].to_i)
  a.title = params[:title]
  a.romaji = params[:romaji]
  a.aliases = params[:aliases]
  a.save

  redirect path_to(:artist).with(a.id)
end

get :album_form do
  protect!

  @album = Album.find(params[:id].to_i)

  slim :album_form, layout: false
end

get :album_line do
  protect!

  album = Album.find(params[:id].to_i)
  slim :album_line, layout: false, locals: {album: album}
end

get :album do
  protect!

  @album = Album.find(params[:id])
  @tracks = @album.all_tracks
  @notes = {}
  Note.where(parent_type: 't', parent_id: @tracks).each do |n|
    @notes[n.parent_id] ||= []
    @notes[n.parent_id] << n
  end

  @title = "#{@album.artists.first.title} - #{@album.title}"
  slim :album
end

post :album do
  protect!

  album = Album.find(params[:id].to_i)
  album.year = params[:year].to_i
  album.primary_type = params[:type]
  album.title = params[:title]
  album.romaji = params[:romaji].empty? ? nil : params[:romaji]
  album.save

  slim :album_line, layout: false, locals: {album: album}
end

post :albums do
  protect!

  artist = Artist.find(params[:artist_id].to_i)
  album = Album.create(
        filename: params[:filename],
        year: params[:year].to_i || nil,
        title: params[:title],
        romaji: params[:romaji].empty? ? nil : params[:romaji],
        primary_type: params[:type]
  )
  artist.albums << album

  # get_album_cover needs album with ID (ie: saved object) and artist ID link
  album.has_cover = (get_album_cover(album) == 0 ? 0 : 1)
  album.save

  redirect path_to(:artist).with(artist.id)
end

def extract_cover(path, filename)
  if File.exist?(filename)
    ID3Tag.read(File.open(filename, "rb")).all_frames_by_id(:APIC).each do |pic|
      random = (0...8).map { [('a'..'z').to_a, (0..9).to_a].flatten[rand(36)] }.join
      if MIME_EXT.include?(pic.mime_type)
        type = MIME_EXT[pic.mime_type]
        cover_filename = File.exist?("#{path}/cover.#{type}") ? "#{path}/cover_#{random}.#{type}" : "#{path}/cover.#{type}"

        cover_file = File.open(cover_filename, 'w')
        cover_file.write(pic.content)
        cover_file.close
      end
    end
  end
end

def get_album_cover_file(path)
  old_pwd = Dir.pwd
  Dir.chdir(path)

  ['cover', 'front', 'folder'].each do |n|
    ['jpg', 'jpeg', 'png'].each do |ext|
      files = Dir.glob("**/#{n}.#{ext}", File::FNM_CASEFOLD)
      if files.count > 0
        Dir.chdir(old_pwd)
        return File.expand_path(files.first, path)
      end
    end
  end
  Dir.chdir(old_pwd)
  return nil
end

def process_album_cover(album_id, cover_path)
  img = MiniMagick::Image.open(cover_path)
  ext = MIME_EXT[img.mime_type] || 'jpg'
  orig_cover_path = File.expand_path("orig/#{album_id}.#{ext}", $covers_path)
  thumb_cover_path = File.expand_path("thumb/#{album_id}.#{ext}", $covers_path)

  FileUtils.copy(cover_path, orig_cover_path)

  if [img.width, img.height].max > 400
    img.resize("400x400>")
    img.write(thumb_cover_path)
  else
    FileUtils.copy(cover_path, thumb_cover_path)
  end
  img.destroy! # remove temp file

  FileUtils.chmod(0644, orig_cover_path)
  FileUtils.chmod(0644, thumb_cover_path)
end

def get_album_cover(album)
  begin
    cover_path = get_album_cover_file(album.full_path)

    unless cover_path
      mp3_file_path = File.join(album.full_path, album.all_tracks.first.filename)
      if mp3_file_path
        extract_cover(album.full_path, mp3_file_path)
        cover_path = get_album_cover_file(album.full_path)
      end
    end

    raise StandardError.new("No cover art found in album directory") unless cover_path

    process_album_cover(album.id, cover_path)

    return album.id
  rescue StandardError => e
    puts "== Error: #{e}"
    return 0 # nocover placeholder
  end
end

post :set_album_cover_from_url do
  protect!

  album = Album.find(params[:id].to_i)

  if params[:url].empty?
    album.has_cover = (get_album_cover(album) == 0 ? 0 : 1)
    album.save
  else
    if params[:url] =~ /redacted\.ch/
      params[:url] = URI.decode(params[:url].gsub(/.*i=/, '').gsub(/&.*/, ''))
    end

    saved_file = Tempfile.new('tulip')
    open(params[:url]) do |read_file|
      saved_file.write(read_file.read)
    end
    saved_file.close

    process_album_cover(album.id, saved_file.path)

    saved_file.unlink

    album.has_cover = 1
    album.save
  end

  slim :album_line, layout: false, locals: {album: album}
end

get :lastfm_tags do
  protect!

  artist = Artist.find(params[:id].to_i)
  tags = $lastfm.artist.get_top_tags(artist: artist.title)
  slim :tags_list, layout: false, locals: {tags_array: tags}
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

post :track_rating do
  protect!

  track = Track.find(params[:id])
  halt(500, "Error") unless track
  track.rating = params[:rating]
  track.save
  halt(200, track.rating.to_s)
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

def escape_apos(text)
#  temp = text.gsub("'", "¤'")
#  return temp.gsub("¤", 92.chr)
  return text.gsub("'", "'\"'\"'") # xx'yy -> xx'"'"'yy (same as '...xx' + "'" + 'yy...')
end

get :download do
  protect!

  track = Track.find(params[:id])
  while File.exist?(tmpfile = "public/lib/#{SecureRandom.hex}") do end
  File.symlink(track.full_path, tmpfile)

  # Sinatra's 'redirect' function not used because it inserts host to 'Location' header
  status 302
  response['Location'] = tmpfile.gsub(/^public/, '')
  return
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

