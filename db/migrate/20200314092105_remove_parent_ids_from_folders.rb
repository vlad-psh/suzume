class RemoveParentIdsFromFolders < ActiveRecord::Migration[6.0]
  def change
    remove_column :folders, :parent_ids, :jsonb
    remove_column :folders, :folder_id, :bigint
  end
end
