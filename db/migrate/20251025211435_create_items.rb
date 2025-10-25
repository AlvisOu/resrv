class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name
      t.integer :quantity
      t.datetime :start_time
      t.datetime :end_time
      t.references :workspace, foreign_key: true

      t.timestamps
    end
  end
end
