class CreateArtistsAlbumsTagsTables < ActiveRecord::Migration[5.0]
  def change
    create_table :artists do |t|
      t.string :discogs_id
      t.string :filename
      t.string :title
      t.timestamps null: false
    end

    create_table :albums do |t|
      t.string :discogs_id
      t.string :filename
      t.string :title
      t.timestamps null: false
    end

    create_table :albums_artists do |t|
      t.belongs_to :artist, index: true
      t.belongs_to :album, index: true
      t.timestamps null: false
    end

    create_table :tags do |t|
      t.string :title
      t.timestamps null: false
    end

    create_table :artists_tags do |t|
      t.belongs_to :artist, index: true
      t.belongs_to :tag, index: true
      t.timestamps null: false
    end

    create_table :albums_tags do |t|
      t.belongs_to :album, index: true
      t.belongs_to :tag, index: true
      t.timestamps null: false
    end
  end
end
