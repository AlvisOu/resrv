class AddCartHoldsToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :in_cart, :boolean, null: false, default: false
    add_column :reservations, :hold_expires_at, :datetime
    add_index  :reservations, [:item_id, :in_cart, :hold_expires_at], name: "idx_res_item_cart_exp"
  end
end
