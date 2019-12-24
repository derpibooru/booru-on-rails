class AddNotesToAdverts < ActiveRecord::Migration[5.1]
  def change
    add_column :adverts, :notes, :string
  end
end
