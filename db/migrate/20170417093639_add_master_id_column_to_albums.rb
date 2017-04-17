class AddMasterIdColumnToAlbums < ActiveRecord::Migration[5.0]
  def change
    add_column :albums, :discogs_master_id, :integer
  end
end
