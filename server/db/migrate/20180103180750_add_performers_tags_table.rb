class AddPerformersTagsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :performers_tags do |t|
      t.belongs_to :performer
      t.belongs_to :tag
    end
  end
end
