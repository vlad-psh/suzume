class AddCoverToReleases < ActiveRecord::Migration[5.2]
  def change
    add_column :releases, :cover, :string
  end
end
