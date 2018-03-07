class AddFoldersTable < ActiveRecord::Migration[5.1]
  def change
    create_table :folders do |t|
      t.string :path
      t.belongs_to :folder
    end
  end
end
