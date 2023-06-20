class AddDirectoryColumnToReleases < ActiveRecord::Migration[5.1]
  def change
    add_column :releases, :directory, :string
  end
end
