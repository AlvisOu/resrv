class AddIsPublicToWorkspaces < ActiveRecord::Migration[8.0]
  def change
    add_column :workspaces, :is_public, :boolean, default: true
  end
end
