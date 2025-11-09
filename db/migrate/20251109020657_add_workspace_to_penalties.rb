class AddWorkspaceToPenalties < ActiveRecord::Migration[8.0]
  def change
    add_reference :penalties, :workspace, foreign_key: true
  end
end
