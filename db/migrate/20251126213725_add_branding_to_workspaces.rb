class AddBrandingToWorkspaces < ActiveRecord::Migration[8.0]
  def change
    add_column :workspaces, :description, :string
  end
end
