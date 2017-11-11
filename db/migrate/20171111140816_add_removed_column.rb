class AddRemovedColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :artists, :is_deleted, :boolean, default: false
    add_column :albums,  :is_deleted, :boolean, default: false
    add_column :tracks,  :is_deleted, :boolean, default: false
  end
end
