class RemoveTagCategoryColumn < ActiveRecord::Migration[5.2]
  def change
    remove_column :tags, :category, :string
  end
end
