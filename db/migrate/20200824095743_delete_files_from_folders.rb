class DeleteFilesFromFolders < ActiveRecord::Migration[6.0]
  def change
    remove_column :folders, :files, :jsonb, default: {}
    remove_column :folders, :is_processed, :boolean, default: false
    remove_column :folders, :nodes, :integer, array: true, default: []
    drop_table :albums_artists
    drop_table :tag_relations
  end
end
