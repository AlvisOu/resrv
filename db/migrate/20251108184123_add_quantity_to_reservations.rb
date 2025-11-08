class AddQuantityToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :quantity, :integer, default: 1, null: false
  end
end
