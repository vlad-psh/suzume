class AddRating < ActiveRecord::Migration[5.1]
  def change
    add_column :artists, :rating, :integer, default: 0
    add_column :albums,  :rating, :integer, default: 0
    add_column :tracks,  :rating, :integer, default: 0
  end
end
