# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_12_10_010458) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "artists", force: :cascade do |t|
    t.string "title"
    t.string "aliases"
    t.jsonb "notes"
    t.string "romaji"
  end

  create_table "artists_tags", force: :cascade do |t|
    t.bigint "artist_id"
    t.bigint "tag_id"
    t.index ["artist_id"], name: "index_artists_tags_on_artist_id"
    t.index ["tag_id"], name: "index_artists_tags_on_tag_id"
  end

  create_table "folders", force: :cascade do |t|
    t.string "path"
    t.boolean "is_removed", default: false
    t.boolean "is_symlink", default: false
    t.string "release_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "playlists_tracks", force: :cascade do |t|
    t.bigint "playlist_id"
    t.bigint "track_id"
    t.index ["playlist_id"], name: "index_playlists_tracks_on_playlist_id"
    t.index ["track_id"], name: "index_playlists_tracks_on_track_id"
  end

  create_table "releases", id: false, force: :cascade do |t|
    t.bigint "artist_id"
    t.string "title"
    t.jsonb "notes"
    t.integer "year"
    t.string "romaji"
    t.string "release_type"
    t.boolean "completed", default: false
    t.string "format"
    t.string "cover"
    t.string "id"
    t.index ["artist_id"], name: "index_releases_on_artist_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "parents", default: [], array: true
  end

  create_table "tracks", force: :cascade do |t|
    t.string "original_filename"
    t.integer "rating"
    t.jsonb "lyrics"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "mediainfo"
    t.jsonb "notes"
    t.string "uid"
    t.string "extension"
    t.bigint "folder_id"
    t.integer "size"
    t.string "title"
    t.string "release_id"
    t.boolean "purged", default: false
    t.index ["folder_id"], name: "index_tracks_on_folder_id"
  end

end
