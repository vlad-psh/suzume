class DeleteTmpTagsProperty < ActiveRecord::Migration[5.2]
  def change
    remove_column :performers, :tmp_tags, :string
    remove_column :releases, :tmp_tags, :string
    remove_column :records, :tmp_tags, :string
  end
end
