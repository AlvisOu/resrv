class MissingReportsController < ApplicationController
  before_action :set_workspace
  before_action :authenticate_owner!

  def index
    @unresolved_reports = @workspace.missing_reports.where(resolved: false).includes(:item, :reservation)
    @resolved_reports   = @workspace.missing_reports.where(resolved: true).includes(:item, :reservation)
  end

  def resolve
    report = @workspace.missing_reports.find(params[:id])
    reservation = report.reservation

    missing_qty = reservation.quantity - reservation.returned_count.to_i

    report.item.increment!(:quantity, missing_qty)

    report.update!(resolved: true)

    flash[:notice] = "Item marked as back online."
    redirect_to workspace_missing_reports_path(@workspace)
  end

  private

  def set_workspace
    @workspace = Workspace.friendly.find(params[:workspace_id])
  end

  def authenticate_owner!
    unless current_user == @workspace.owner
      redirect_to root_path, alert: "Not authorized."
    end
  end
end
