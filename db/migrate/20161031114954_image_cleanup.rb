class ImageCleanup < ActiveRecord::Migration[4.2]
  def change
    reversible do |m|
      m.up do
        change_column_default :images, :description, ''
        change_column_null    :images, :description, false, ''

        rename_column :images, :processing, :processed
        Image.update_all processed: true
      end
      m.down do
        rename_column :images, :processed, :processing
        Image.update_all processing: false
      end
    end
  end
end
