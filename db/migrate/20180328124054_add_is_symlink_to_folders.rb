class AddIsSymlinkToFolders < ActiveRecord::Migration[5.1]
  def change
    add_column :folders, :is_symlink, :boolean, default: false
  end
end
