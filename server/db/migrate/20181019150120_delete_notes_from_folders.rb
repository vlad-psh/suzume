class DeleteNotesFromFolders < ActiveRecord::Migration[5.2]
  def change
    remove_column :folders, :notes, :jsonb, default: []
  end
end
