class AddFormatToReleases < ActiveRecord::Migration[5.2]
  def change
    add_column :releases, :format, :string
  end
end
