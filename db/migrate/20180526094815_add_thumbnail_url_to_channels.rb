class AddThumbnailUrlToChannels < ActiveRecord::Migration[5.1]
  def change
    add_column :channels, :thumbnail_url, :string, default: ''
  end
end
