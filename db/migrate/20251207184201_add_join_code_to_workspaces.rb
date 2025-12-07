class AddJoinCodeToWorkspaces < ActiveRecord::Migration[8.0]
  def change
    add_column :workspaces, :join_code, :string
    add_index :workspaces, :join_code, unique: true
  end
end
