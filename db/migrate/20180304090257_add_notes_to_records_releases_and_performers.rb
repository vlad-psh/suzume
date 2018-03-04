class AddNotesToRecordsReleasesAndPerformers < ActiveRecord::Migration[5.1]
  def change
    add_column :performers, :notes, :jsonb
    add_column :releases, :notes, :jsonb
    add_column :records, :notes, :jsonb
  end
end
