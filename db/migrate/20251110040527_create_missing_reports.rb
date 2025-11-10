class CreateMissingReports < ActiveRecord::Migration[8.0]
  def change
    create_table :missing_reports do |t|
      t.references :reservation, foreign_key: true
      t.references :item, foreign_key: true
      t.references :workspace, foreign_key: true
      t.integer :quantity
      t.boolean :resolved

      t.timestamps
    end
  end
end
