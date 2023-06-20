class AddIsRemovedToFolders < ActiveRecord::Migration[5.1]
  def change
    add_column :folders, :is_removed, :boolean, default: false
  end
end
