class AddStatusColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :artists, :status, :string
    add_column :albums, :status, :string
    add_column :tracks, :status, :string
  end
end
