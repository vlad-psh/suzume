class AddHasCoverColumnToAlbums < ActiveRecord::Migration[5.1]
  def change
    add_column :albums, :has_cover, :integer, default: -1 # -1=undef; 0=false; 1=true
  end
end
