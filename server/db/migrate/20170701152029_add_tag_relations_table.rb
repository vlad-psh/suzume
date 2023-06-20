class AddTagRelationsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_relations do |t|
      t.string :linked_object, index: true # p/r/t + id
      t.belongs_to :tag, index: true
      t.timestamps null: false
    end
  end
end
