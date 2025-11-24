class AddAppealsToPenalties < ActiveRecord::Migration[8.0]
  def change
    add_column :penalties, :appeal_state, :string, default: "none", null: false
    add_column :penalties, :appeal_message, :text
    add_column :penalties, :appealed_at, :datetime
    add_column :penalties, :appeal_resolved_at, :datetime

    add_reference :notifications, :penalty, foreign_key: true
  end
end
