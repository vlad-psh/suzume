class AddWaveformPointsToTracks < ActiveRecord::Migration[7.0]
  def change
    add_column :tracks, :waveform_points, :jsonb
  end
end
