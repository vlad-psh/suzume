class AddUidAndExtensionToRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :records, :uid, :string
    add_column :records, :extension, :string
  end
end
