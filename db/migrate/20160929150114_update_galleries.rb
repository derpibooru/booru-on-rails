class UpdateGalleries < ActiveRecord::Migration[4.2]
  def change
    add_column :galleries, :watcher_ids,        :integer, default: [], null: false, array: true
    add_column :galleries, :watcher_count,      :integer, default: 0,  null: false
    add_column :galleries, :image_count,        :integer, default: 0,  null: false
    add_column :galleries, :order_position_asc, :boolean, default: false

    reversible do |m|
      m.up do
        puts 'Setting image count...'
        Gallery.find_each { |g| g.update_column(:image_count, g.images.count) }
      end
    end

    Gallery.__elasticsearch__.create_index!
    Gallery.import
  end
end
