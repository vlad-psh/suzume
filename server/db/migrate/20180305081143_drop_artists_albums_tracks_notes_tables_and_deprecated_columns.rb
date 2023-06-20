class DropArtistsAlbumsTracksNotesTablesAndDeprecatedColumns < ActiveRecord::Migration[5.1]
  def change
    drop_table :artists
    drop_table :albums
    drop_table :tracks
    drop_table :notes

    remove_column :records, :old_id, :integer
    remove_column :releases, :cover, :string
    remove_column :releases, :old_id, :integer
    remove_column :performers, :old_id, :integer
  end
end
