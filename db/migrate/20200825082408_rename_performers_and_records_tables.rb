class RenamePerformersAndRecordsTables < ActiveRecord::Migration[6.0]
  def change
    rename_column :releases, :performer_id, :artist_id
    rename_column :performers_tags, :performer_id, :artist_id
    rename_column :playlists_records, :record_id, :track_id
    rename_table :performers_tags, :artists_tags
    rename_table :performers, :artists
    rename_table :playlists_records, :playlists_tracks
    rename_table :records, :tracks
  end
end
