class AddCompletedToReleases < ActiveRecord::Migration[5.2]
  def change
    add_column :releases, :completed, :boolean, default: false
  end
end
