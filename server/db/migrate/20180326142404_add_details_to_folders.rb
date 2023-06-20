class AddDetailsToFolders < ActiveRecord::Migration[5.1]
  def change
    add_column :folders, :notes, :jsonb, default: []
    add_column :folders, :files, :jsonb, default: {}
    add_column :folders, :is_processed, :boolean, default: false
  end
end
