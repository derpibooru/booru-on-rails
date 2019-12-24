class AddRemoteStreamIdToChannels < ActiveRecord::Migration[5.0]
  def change
    add_column :channels, :remote_stream_id, :integer
  end
end
