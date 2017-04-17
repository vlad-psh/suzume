class AddFormatsColumnToAlbums < ActiveRecord::Migration[5.0]
  def change
    add_column :albums, :formats, :string
  end
end
