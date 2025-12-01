class WorkspaceUsersController < ApplicationController
  
  before_action :set_workspace
  before_action :authorize_owner!
  before_action :set_user

  def show
    # Reservations ONLY for this workspace
    res_scope = @user.reservations
                     .joins(:item)
                     .where(items: { workspace_id: @workspace.id })
                     .includes(:item)

    now = Time.zone.now

    # ===== SECTION 2 METRICS =====
    @total_reservations = res_scope.count

    @active_reservations =
      res_scope.where("reservations.start_time <= ? AND reservations.end_time >= ?", now, now)

    @upcoming_reservations =
      res_scope.where("reservations.start_time > ?", now).order("reservations.start_time ASC")

    @past_reservations =
      res_scope.where("reservations.end_time < ?", now).order("reservations.end_time DESC")

    @no_show_count =
      res_scope.where("reservations.no_show = ?", true).count

    @late_return_count =
      res_scope.select { |r| r.returned_count < r.quantity && r.end_time < now }.count

    @missing_events_count =
      MissingReport.joins(:reservation)
                  .where(reservations: { id: res_scope.select(:id) })
                  .count

    # Most commonly used items
    @item_usage =
      res_scope
      .group("items.name")
      .count
      .sort_by { |_, v| -v }

    # Average reservation duration
    durations = res_scope.map { |r| (r.end_time - r.start_time) / 3600.0 } # hours
    @avg_duration = durations.empty? ? 0 : (durations.sum / durations.size)

    # Reliability score
    @reliability_score =
      if @total_reservations.zero?
        1.0
      else
        successful = @total_reservations - (@no_show_count + @late_return_count)
        successful.to_f / @total_reservations
      end
  end

  private

  def set_workspace
    @workspace = Workspace.friendly.find(params[:workspace_id])
  end

  def set_user
    @user = User.friendly.find(params[:id])
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized." unless current_user_is_owner?(@workspace)
  end
end
