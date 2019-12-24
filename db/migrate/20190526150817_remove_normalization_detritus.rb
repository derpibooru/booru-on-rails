class RemoveNormalizationDetritus < ActiveRecord::Migration[5.2]
  def change
    drop_table :user_links_2
  end
end
