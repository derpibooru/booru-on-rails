class SetTimeDefaults < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    change_column_default :user_fingerprints, :created_at, from: nil, to: -> { 'now()' }
    change_column_default :user_fingerprints, :updated_at, from: nil, to: -> { 'now()' }
    change_column_default :user_ips, :created_at, from: nil, to: -> { 'now()' }
    change_column_default :user_ips, :updated_at, from: nil, to: -> { 'now()' }
    change_column_null :user_fingerprints, :updated_at, false
    change_column_null :user_ips, :updated_at, false
  end
end
