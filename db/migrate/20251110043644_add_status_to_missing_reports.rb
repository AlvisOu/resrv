class AddStatusToMissingReports < ActiveRecord::Migration[8.0]
  def change
    add_column :missing_reports, :status, :string
  end
end
