class CreateVpns < ActiveRecord::Migration[5.1]
  def change
    create_table :vpns, id: false do |t|
      t.inet :ip, null: false
    end

    execute "create index index_vpns_on_ip on vpns using gist (ip inet_ops)"
  end
end
