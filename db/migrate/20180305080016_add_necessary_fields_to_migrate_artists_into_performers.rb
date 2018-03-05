class AddNecessaryFieldsToMigrateArtistsIntoPerformers < ActiveRecord::Migration[5.1]
  def change
    add_column :performers, :romaji, :string
  end
end
