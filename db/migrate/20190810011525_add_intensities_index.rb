class AddIntensitiesIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :image_intensities, [:nw, :ne, :sw, :se], name: :image_intensities_index
  end
end
