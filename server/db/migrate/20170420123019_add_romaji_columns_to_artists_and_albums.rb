class AddRomajiColumnsToArtistsAndAlbums < ActiveRecord::Migration[5.0]
  def change
    add_column :artists, :romaji, :string
    add_column :albums, :romaji, :string
  end
end
