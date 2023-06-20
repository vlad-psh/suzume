class RemoveAliasesFromReleases < ActiveRecord::Migration[5.1]
  def change
    remove_column :releases, :aliases, :string
  end
end
