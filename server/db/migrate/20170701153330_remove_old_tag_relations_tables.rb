class RemoveOldTagRelationsTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :artists_tags
    drop_table :albums_tags
  end
end
