class AddPurgedToTracks < ActiveRecord::Migration[7.0]
  def change
    add_column :tracks, :purged, :boolean, default: false
  end
end
