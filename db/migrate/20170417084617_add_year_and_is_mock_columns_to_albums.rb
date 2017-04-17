class AddYearAndIsMockColumnsToAlbums < ActiveRecord::Migration[5.0]
  def change
    add_column :albums, :year, :integer
    add_column :albums, :is_mock, :boolean, default: true
  end
end
