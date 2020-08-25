class RemoveDefaultFromTracksRating < ActiveRecord::Migration[6.0]
  def change
    change_column_default :tracks, :rating, from: 0, to: nil
  end
end
