class AddSlugsToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :workspaces, :slug, :string
    add_index :workspaces, :slug, unique: true

    add_column :items, :slug, :string
    add_index :items, :slug, unique: true

    add_column :users, :slug, :string
    add_index :users, :slug, unique: true
  end
end
