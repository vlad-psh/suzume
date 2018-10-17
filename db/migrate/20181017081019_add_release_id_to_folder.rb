class AddReleaseIdToFolder < ActiveRecord::Migration[5.2]
  def change
    add_column :folders, :release_id, :integer
  end
end
