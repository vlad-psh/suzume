class AddTagsStrColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :artists, :tagsstr, :string
    add_column :albums, :tagsstr, :string
    add_column :tracks, :tagsstr, :string
  end
end
