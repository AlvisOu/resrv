class CreateEquipment < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment do |t|
      t.references :workspace, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :quantity, null: false, default: 1
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :equipment, [:workspace_id, :name], unique: true
  end
end
