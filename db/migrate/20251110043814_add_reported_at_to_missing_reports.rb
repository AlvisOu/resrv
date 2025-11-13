class AddReportedAtToMissingReports < ActiveRecord::Migration[8.0]
  def change
    add_column :missing_reports, :reported_at, :datetime
  end
end
