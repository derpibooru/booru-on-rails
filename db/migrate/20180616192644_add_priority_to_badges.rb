class AddPriorityToBadges < ActiveRecord::Migration[5.1]
  def change
    # Add priority column
    add_column :badges, :priority, :boolean, default: false

    # Normalize disable_award values to convert any NULLs to false
    execute "UPDATE badges SET disable_award = false WHERE disable_award IS NULL"
    # Then disable NULLing the disable_award column
    change_column_null :badges, :disable_award, false

    # Copy disable_award values to the priority column
    execute "UPDATE badges SET priority = disable_award"
  end
end
