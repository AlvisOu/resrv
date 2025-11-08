class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, foreign_key: true
      t.text :message
      t.boolean :read, default: false, null: false
      t.references :reservation, foreign_key: true

      t.timestamps
    end
  end
end