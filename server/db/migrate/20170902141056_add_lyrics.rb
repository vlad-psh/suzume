class AddLyrics < ActiveRecord::Migration[5.1]
  def change
    add_column :tracks, :lyrics_json, :string
  end
end
