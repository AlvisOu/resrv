class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :reservations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :equipment, null: false, foreign_key: true
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.integer :quantity, null: false, default: 1
      t.string :status, null: false, default: "pending"
      t.text :notes

      t.timestamps
    end
    add_index :reservations, [:equipment_id, :start_at, :end_at], name: 'index_reservations_on_equipment_and_time'
    add_index :reservations, [:user_id, :start_at, :end_at], name: 'index_reservations_on_user_and_time'
  end
end
