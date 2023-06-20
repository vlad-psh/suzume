class AddDefaultValueToStatus < ActiveRecord::Migration[5.1]
  def change
    change_column_default :tracks, :status, ''
    change_column_default :albums, :status, ''
    change_column_default :artists, :status, ''
  end
end
