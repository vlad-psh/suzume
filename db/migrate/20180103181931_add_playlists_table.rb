class AddPlaylistsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :playlists do |t|
      t.string :title
      t.string :description
      t.timestamps null: false
    end

    create_table :playlists_records do |t|
      t.belongs_to :playlist
      t.belongs_to :record
    end
  end
end
