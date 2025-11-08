class AddStatusToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :no_show, :boolean, default: false, null: false
    add_column :reservations, :not_returned, :boolean, default: false, null: false
  end
end
