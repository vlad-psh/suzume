class AddMediainfoColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :tracks, :mediainfo, :jsonb
    add_column :records, :mediainfo, :jsonb
  end
end
