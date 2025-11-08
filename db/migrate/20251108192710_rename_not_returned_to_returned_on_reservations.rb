class RenameNotReturnedToReturnedOnReservations < ActiveRecord::Migration[8.0]
  def change
    remove_column :reservations, :not_returned, :boolean
    add_column :reservations, :returned_count, :integer, default: 0, null: false
  end
end
