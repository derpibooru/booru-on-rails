class AddBadgeNameToBadgeAwards < ActiveRecord::Migration[4.2]
  def change
    add_column :badge_awards, :badge_name, :string
  end
end
