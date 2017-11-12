class CreateNewTables < ActiveRecord::Migration[5.1]
  def change
    create_table :performers do |t|
      t.string :title
      t.string :aliases

      t.string :tmp_tags
      t.integer :old_id
    end
    create_table :releases do |t|
      t.belongs_to :performer
      t.string :title # year title, eg.: "1998 merveilles"
      t.string :aliases # may be unnecessary; we'll see it later
      t.string :cover # hash to cover

      t.string :tmp_tags
      t.integer :old_id # needed to preserve old relations
    end
    create_table :records do |t| # will rename later to 'tracks'
      t.belongs_to :release, null: false # if doesn't belongs to any release,
                                         # performer's [default release] should be assigned
      t.string :original_filename
      t.string :filename
      t.string :directory
      t.integer :rating, default: 0
      t.jsonb :lyrics

      t.string :tmp_tags
      t.integer :old_id

      t.timestamps null: false
    end

    # temporary
    add_column :artists, :is_processed, :boolean, default: false
    add_column :albums,  :is_processed, :boolean, default: false
    add_column :tracks,  :is_processed, :boolean, default: false
  end
end
