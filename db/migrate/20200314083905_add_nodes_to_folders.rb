class AddNodesToFolders < ActiveRecord::Migration[6.0]
  def change
    add_column :folders, :nodes, :integer, array: true, default: []
  end
end
