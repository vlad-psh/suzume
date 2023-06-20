class AddNecessaryFieldsToMigrateAlbumsIntoReleases < ActiveRecord::Migration[5.1]
  def change
    add_column :releases, :year, :integer
    add_column :releases, :romaji, :string
    add_column :releases, :release_type, :string
#    remove_column :releases, :cover, :string
#    remove_column :releases, :old_id, :integer # should be removed later
  end
end
