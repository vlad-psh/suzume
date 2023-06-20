class AddArtistAliasesColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :artists, :aliases, :string
  end
end
