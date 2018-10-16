# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_10_16_093451) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "albums_artists", id: :serial, force: :cascade do |t|
    t.integer "artist_id"
    t.integer "album_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_albums_artists_on_album_id"
    t.index ["artist_id"], name: "index_albums_artists_on_artist_id"
  end

  create_table "folders", force: :cascade do |t|
    t.string "path"
    t.bigint "folder_id"
    t.jsonb "parent_ids"
    t.jsonb "notes", default: []
    t.jsonb "files", default: {}
    t.boolean "is_processed", default: false
    t.boolean "is_removed", default: false
    t.boolean "is_symlink", default: false
    t.index ["folder_id"], name: "index_folders_on_folder_id"
  end

  create_table "performers", force: :cascade do |t|
    t.string "title"
    t.string "aliases"
    t.string "tmp_tags"
    t.jsonb "notes"
    t.string "romaji"
  end

  create_table "performers_tags", force: :cascade do |t|
    t.bigint "performer_id"
    t.bigint "tag_id"
    t.index ["performer_id"], name: "index_performers_tags_on_performer_id"
    t.index ["tag_id"], name: "index_performers_tags_on_tag_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "playlists_records", force: :cascade do |t|
    t.bigint "playlist_id"
    t.bigint "record_id"
    t.index ["playlist_id"], name: "index_playlists_records_on_playlist_id"
    t.index ["record_id"], name: "index_playlists_records_on_record_id"
  end

  create_table "records", force: :cascade do |t|
    t.bigint "release_id", null: false
    t.string "original_filename"
    t.string "directory"
    t.integer "rating", default: 0
    t.jsonb "lyrics"
    t.string "tmp_tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "mediainfo"
    t.jsonb "notes"
    t.string "uid"
    t.string "extension"
    t.index ["release_id"], name: "index_records_on_release_id"
  end

  create_table "releases", force: :cascade do |t|
    t.bigint "performer_id"
    t.string "title"
    t.string "tmp_tags"
    t.string "directory"
    t.jsonb "notes"
    t.integer "year"
    t.string "romaji"
    t.string "release_type"
    t.boolean "completed", default: false
    t.index ["performer_id"], name: "index_releases_on_performer_id"
  end

  create_table "tag_relations", force: :cascade do |t|
    t.string "linked_object"
    t.bigint "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "parent_type"
    t.integer "parent_id"
    t.index ["linked_object"], name: "index_tag_relations_on_linked_object"
    t.index ["tag_id"], name: "index_tag_relations_on_tag_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
  end

end
