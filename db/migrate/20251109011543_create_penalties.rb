class CreatePenalties < ActiveRecord::Migration[8.0]
  def change
    create_table :penalties do |t|
      t.references :user, foreign_key: true
      t.string :reason
      t.datetime :expires_at
      t.references :reservation, foreign_key: true

      t.timestamps
    end
  end
end
