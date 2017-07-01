class AddParentIdAndParentTypeInTagRelations < ActiveRecord::Migration[5.1]
  def change
    add_column :tag_relations, :parent_type, :string, index: true
    add_column :tag_relations, :parent_id, :integer, index: true
  end
end
