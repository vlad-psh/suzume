class RemoveOldReleaseId < ActiveRecord::Migration[6.1]
  def change
    remove_column :releases, :id, :primary_key
    remove_column :releases, :directory, :string

    remove_column :tracks, :release_id, :bigint, null: false
    remove_column :tracks, :directory, :string

    remove_column :folders, :release_id, :bigint, null: false

    rename_column :releases, :uid, :id
    rename_column :tracks, :release_uid, :release_id
    rename_column :folders, :release_uid, :release_id
  end
end
