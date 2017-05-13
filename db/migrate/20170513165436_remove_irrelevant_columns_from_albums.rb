class RemoveIrrelevantColumnsFromAlbums < ActiveRecord::Migration[5.1]
  def change
    remove_column :albums, :date, :date
    remove_column :albums, :secondary_type, :string
    remove_column :albums, :is_mock, :boolean
  end
end
