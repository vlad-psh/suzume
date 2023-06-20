class DeleteFilenameFromRecords < ActiveRecord::Migration[5.2]
  def change
    remove_column :records, :filename, :string
  end
end
