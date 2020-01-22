class AddTagsInheritance < ActiveRecord::Migration[6.0]
  def change
    add_column :tags, :parents, :integer, array: true, default: []
  end
end
