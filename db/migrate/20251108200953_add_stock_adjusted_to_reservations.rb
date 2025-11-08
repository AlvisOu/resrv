class AddStockAdjustedToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :stock_adjusted, :boolean, default: false, null: false
  end
end
