class AddAbyssFieldsToRecords < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :records, :folder
    add_column :records, :size, :integer
    add_column :records, :title, :string
  end
end
