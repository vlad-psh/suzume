class AddTracksAndNotesTables < ActiveRecord::Migration[5.1]
  def change
    create_table :tracks do |t|
      t.belongs_to :album
      t.string :filename
      t.timestamps null: false
    end
    create_table :notes do |t|
      t.string :parent_type, null: false # p = performer, r = release, t = track
      t.integer :parent_id, null: false
      t.string :content
      t.timestamps null: false
    end
  end
end
