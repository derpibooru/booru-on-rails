class AddDisableawardToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :disable_award, :boolean, default: false
  end
end
