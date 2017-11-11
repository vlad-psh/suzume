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

ActiveRecord::Schema.define(version: 20171111140816) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "albums", id: :serial, force: :cascade do |t|
    t.string "mbid"
    t.string "filename"
    t.string "title"
    t.string "primary_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "romaji"
    t.integer "year"
    t.integer "has_cover", default: -1
    t.integer "rating", default: 0
    t.boolean "is_deleted", default: false
  end

  create_table "albums_artists", id: :serial, force: :cascade do |t|
    t.integer "artist_id"
    t.integer "album_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_albums_artists_on_album_id"
    t.index ["artist_id"], name: "index_albums_artists_on_artist_id"
  end

  create_table "artists", id: :serial, force: :cascade do |t|
    t.string "mbid"
    t.string "filename"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "romaji"
    t.string "aliases"
    t.integer "rating", default: 0
    t.boolean "is_deleted", default: false
  end

  create_table "notes", force: :cascade do |t|
    t.string "parent_type", null: false
    t.integer "parent_id", null: false
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "tracks", force: :cascade do |t|
    t.bigint "album_id"
    t.string "filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rating", default: 0
    t.string "lyrics_json"
    t.boolean "is_deleted", default: false
    t.index ["album_id"], name: "index_tracks_on_album_id"
  end

end
