require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
require 'discogs-wrapper'

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
  $discogs = Discogs::Wrapper.new($config['useragent'],
                    user_token: $config['discogs_token'])

  use Rack::Flash
end

def get_tulip_id(dir)
  tulip_files = Dir.glob(File.expand_path("*.tulip", dir))
  tulip_match = tulip_files.count > 0 ? tulip_files[0].match(/.*\/(?<tulip_id>[0-9]*)\.tulip/) : nil
  tulip_id = tulip_match ? tulip_match[:tulip_id] : nil
  return tulip_id
end

def update_artist_albums(artist)
  page = 0
  artist_albums = artist.albums
  begin 
    page += 1
    artist_releases = $discogs.get_artist_releases(artist.discogs_id, page: page)
    artist_releases.releases.each do |r|
      if r.role == "Main"
        if r.type == "master"
          album = Album.find_or_initialize_by(discogs_id: r.main_release)
          album.update_attributes(
                year: r.year,
                title: r.title,
                discogs_master_id: r.id)
          album.save
          artist.albums << album unless artist_albums.include?(album)
        elsif r.type == "release"
          album = Album.find_or_initialize_by(discogs_id: r.id)
          album.update_attributes(
                year: r.year,
                title: r.title,
                formats: r.format.split(", ").join("|"))
          album.save
          artist.albums << album unless artist_albums.include?(album)
        else
          puts "!!! Unknown album type: #{r.type}"
        end
      else
        # if role != "Main" we do not need these records
        # as of Apr.2017, "Main" records are always first
        # that's why we can simply end process of further reading
        page = artist_releases.pagination.pages
      end
    end
  end while page < artist_releases.pagination.pages
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
  all_albums = @artist.albums.order(year: :desc) # is_mock: :asc

  @albums = {albums: [], eps: [], singles: [], compillations: [], other: []}

  all_albums.each do |a|
    if a.formats == nil || a.formats.include?("Reissue") || a.formats.include?("RE")
      @albums[:other] << a
    elsif a.formats.include?("Comp")
      @albums[:compillations] << a
    elsif a.formats.include?("Album")
      @albums[:albums] << a
    elsif a.formats.include?("EP")
      @albums[:eps] << a
    elsif a.formats.include?("Single") || a.formats.include?("Maxi")
      @albums[:singles] << a
    else
      @albums[:other] << a
    end
  end

  @new_albums = []
  artist_dir = File.expand_path(@artist.filename, $library_path)
  Dir.entries(artist_dir).each do |dir|
    next if [".", ".."].include?(dir)
    next if all_albums.any? { |a| a.filename == dir }
    @new_albums << dir if File.directory?(File.expand_path(dir, artist_dir))
  end

  slim :artist
end

post :artist_set_discogs_id do
  a = Artist.find_or_create_by(filename: params[:filename])
  a.discogs_id = params[:discogs_id].gsub(/[^0-9]/, '').to_i
  a.title = params[:filename]
  a.save

  update_artist_albums(a)

  redirect path_to(:artist).with(a.id)
end

post :album_set_discogs_id do
  d_id = params[:discogs_id].gsub(/[^0-9]/, '').to_i
  a = Album.where(discogs_id: d_id).take

  if a != nil
    release = $discogs.get_release(d_id)
    a.formats = [release.formats[0].name, release.formats[0].descriptions].flatten.join('|')

    a.filename = params[:filename]
    a.is_mock = false
    a.save
    flash[:notice] = "Successfully assigned discogs_id = #{d_id} to \"#{params[:filename]}\""
  else
    flash[:error] = "Unable to find Album with discogs_id = #{d_id}"
  end

  redirect path_to(:artist).with(params[:artist_id].to_i)
end
