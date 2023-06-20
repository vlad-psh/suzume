class AddYearColumnToAlbums < ActiveRecord::Migration[5.1]
  def change
    add_column :albums, :year, :integer
  end
end
