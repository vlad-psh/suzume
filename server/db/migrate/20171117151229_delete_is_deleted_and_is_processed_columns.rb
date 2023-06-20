class DeleteIsDeletedAndIsProcessedColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :artists, :is_deleted
    remove_column :albums,  :is_deleted
    remove_column :tracks,  :is_deleted
    remove_column :artists, :is_processed
    remove_column :albums,  :is_processed
    remove_column :tracks,  :is_processed
  end
end
