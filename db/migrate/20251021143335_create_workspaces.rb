class CreateWorkspaces < ActiveRecord::Migration[8.0]
  def change
    create_table :workspaces do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :timezone

      t.timestamps
    end
    add_index :workspaces, :slug, unique: true
  end
end
