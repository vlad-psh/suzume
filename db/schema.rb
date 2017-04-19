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

ActiveRecord::Schema.define(version: 20170419172945) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "albums", force: :cascade do |t|
    t.string   "mbid"
    t.string   "filename"
    t.string   "title"
    t.date     "date"
    t.boolean  "is_mock",        default: true
    t.string   "primary_type"
    t.string   "secondary_type"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "albums_artists", force: :cascade do |t|
    t.integer  "artist_id"
    t.integer  "album_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_albums_artists_on_album_id", using: :btree
    t.index ["artist_id"], name: "index_albums_artists_on_artist_id", using: :btree
  end

  create_table "albums_tags", force: :cascade do |t|
    t.integer  "album_id"
    t.integer  "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_albums_tags_on_album_id", using: :btree
    t.index ["tag_id"], name: "index_albums_tags_on_tag_id", using: :btree
  end

  create_table "artists", force: :cascade do |t|
    t.string   "mbid"
    t.string   "filename"
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "artists_tags", force: :cascade do |t|
    t.integer  "artist_id"
    t.integer  "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_artists_tags_on_artist_id", using: :btree
    t.index ["tag_id"], name: "index_artists_tags_on_tag_id", using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end