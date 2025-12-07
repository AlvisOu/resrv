require "csv"

class WorkspacesController < ApplicationController
  before_action :set_workspace, only: [
    :show, 
    :edit, 
    :update, 
    :past_reservations,
    :analytics,
    :analytics_utilization_csv,
    :analytics_behavior_csv,
    :analytics_heatmap_csv
  ]
  before_action :authorize_owner!, only: [:edit, :update]

  def index
    if params[:query].present?
      query = params[:query]
      @workspaces = Workspace.public_workspaces
                             .where("id = ? OR LOWER(name) LIKE ?", query.to_i, "%#{query.downcase}%")
    else
      @owned_workspaces = current_user.owned_workspaces
      @joined_workspaces = current_user.joined_workspaces
    end
  end

  def create
    @workspace = Workspace.new(workspace_params)

    if @workspace.save
      UserToWorkspace.create(user: current_user, workspace: @workspace, role: 'owner')
      redirect_to @workspace, notice: 'Workspace was successfully created.'
    else
      render :new
    end
  end

  def update
    if @workspace.update(workspace_params)
      redirect_to @workspace, notice: 'Workspace was successfully updated.'
    else
      # render errors so the feature can see "prohibited this workspace..."
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @workspace = Workspace.new
  end
  
  def show
    @current_join = @workspace.user_to_workspaces.find_by(user: current_user)
    @penalty = current_user.penalties.active.find_by(workspace: @workspace)
    @items = @workspace.items.reload.includes(:reservations)

    @tz = Time.zone || ActiveSupport::TimeZone["UTC"]
    today = @tz.today
    max_day = today + 7.days

    # Parse & clamp selected day (GET /workspaces/:id?day=YYYY-MM-DD)
    requested_day =
      begin
        Date.iso8601(params[:day]) if params[:day].present?
      rescue ArgumentError
        nil
      end

    @day = requested_day || today
    @day = today  if @day < today
    @day = max_day if @day > max_day

    # For the header: precompute 96 ticks for @day
    @slots = []
    day_start = @tz.local(@day.year, @day.month, @day.day, 0, 0, 0)
    96.times { |i| @slots << (day_start + i * 15.minutes) }

    # Booking window: now → (today + 7 days) end-of-day
    now = @tz.now
    window_start = [day_start, ceil_to_15(now)].max # greys out past for today
    window_end   = (today + 7.days).in_time_zone(@tz).end_of_day

    # Availability for default quantity = 1 (initial paint) for selected @day
    @availability_data = @items.map do |item|
      {
        item: item,
        slots: AvailabilityService.new(
          item, 1,
          day: @day, tz: @tz,
          window_start: window_start,
          window_end: window_end
        ).time_slots
      }
    end

    # --- NEW: build booking tooltips for owners on the selected day ---
    is_owner = @current_join&.role == 'owner'
    day_end  = day_start + 24.hours

    # --- Quick workspace summary stats for admin ---
    summary_items = @workspace.items
    # Reservation trend: last 7 days vs previous 7 days
    now = Time.current
    last_week_start   = now - 7.days
    prev_week_start   = now - 14.days

    # Most used item (recent 7 days)
    @top_item = summary_items
    .left_joins(:reservations)
    .where(reservations: { start_time: last_week_start..now })
    .group("items.id")
    .order("COUNT(reservations.id) DESC")
    .first

    # Least used item (recent 7 days)
    @least_item = summary_items
    .left_joins(:reservations)
    .where(reservations: { start_time: last_week_start..now })
    .group("items.id")
    .order("COUNT(reservations.id) ASC")
    .first

    @this_week_count = Reservation
      .where(item_id: summary_items.ids, start_time: last_week_start..now)
      .count

    @prev_week_count = Reservation
      .where(item_id: summary_items.ids, start_time: prev_week_start..last_week_start)
      .count

    # determine trend direction
    @weekly_trend =
      if @prev_week_count.zero? && @this_week_count.zero?
        :flat
      elsif @prev_week_count.zero? && @this_week_count > 0
        :up
      elsif @this_week_count > @prev_week_count
        :up
      elsif @this_week_count < @prev_week_count
        :down
      else
        :flat
      end

    if is_owner
      # Reservations that overlap the selected day, with users preloaded
      day_reservations = Reservation
        .joins(:item)
        .includes(:user) # so we can show names without N+1
        .where(items: { workspace_id: @workspace.id })
        .where("reservations.start_time < ? AND reservations.end_time > ?", day_end, day_start)

      @booking_tooltips = Hash.new { |h, item_id| h[item_id] = Hash.new { |hh, ts| hh[ts] = [] } }

      day_reservations.each do |r|
        s = [r.start_time.in_time_zone(@tz), day_start].max
        e = [r.end_time.in_time_zone(@tz),   day_end  ].min

        t = floor_to_15(s)
        while t < e
          key = t.iso8601
          @booking_tooltips[r.item_id][key] << {
            id: r.id,
            label: "#{r.user.name} ×#{r.quantity}"
          }
          t += 15.minutes
        end
      end
    end

    # Current activity block (unchanged)
    @current_activity = Reservation.joins(:item)
                                  .where(items: { workspace_id: @workspace.id })
                                  .where("reservations.start_time <= ? AND reservations.end_time >= ?", now, now - 30.minutes)
                                  .includes(:user, :item)
                                  .order("reservations.end_time ASC")

    # Sweep any overdue reservations (ended >30 minutes ago) to auto-create missing reports.
    Reservation.joins(:item)
               .where(items: { workspace_id: @workspace.id })
               .where("reservations.end_time <= ?", now - 30.minutes)
               .where("reservations.start_time >= ?", now - 30.days) # small window to avoid scanning everything
               .find_each do |reservation|
      reservation.auto_mark_missing_items
    end

    @unresolved_reports = @workspace.missing_reports.where(resolved: false).includes(:item, reservation: :user)
    @resolved_reports   = @workspace.missing_reports.where(resolved: true).includes(:item, reservation: :user)

    if is_owner
      @filter_day =
        begin
          Date.iso8601(params[:filter_day]) if params[:filter_day].present?
        rescue ArgumentError
          nil
        end || today

      day_start = @tz.local(@filter_day.year, @filter_day.month, @filter_day.day, 0, 0, 0)
      day_end   = day_start.end_of_day

      @filter_item_id = params[:filter_item_id].presence

      upcoming_scope = Reservation
        .joins(:item)
        .includes(:user, :item)
        .where(items: { workspace_id: @workspace.id })
        .where("reservations.start_time >= ?", @tz.now)

      if params[:filter_day].present?
        upcoming_scope = upcoming_scope.where(reservations: { start_time: day_start..day_end })
      end

      if @filter_item_id
        upcoming_scope = upcoming_scope.where(items: { id: @filter_item_id })
      end

      @upcoming_reservations = upcoming_scope.order(:start_time)
    end

  end

  def edit
  end

  def update
    if @workspace.update(workspace_params)
      redirect_to @workspace, notice: "Workspace updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def past_reservations
    # reuse the same tz as show, or fall back to Time.zone
    @tz = @tz || Time.zone

    @past_reservations = Reservation
      .joins(:item)
      .where(items: { workspace_id: @workspace.id })
      .where("reservations.end_time < ?", @tz.now)
      .includes(:user, :item)
      .order(end_time: :desc)
  end

  def analytics
    @current_join = @workspace.user_to_workspaces.find_by(user: current_user)
    authorize_owner!

    # ========= RANGE SELECTION =========
    range = params[:range].presence || "7d"
    now = Time.zone.now

    case range
    when "7d"   then @start_date = now - 7.days
    when "1m"   then @start_date = now - 1.month
    when "3m"   then @start_date = now - 3.months
    when "6m"   then @start_date = now - 6.months
    when "1y"   then @start_date = now - 1.year
    when "all"  then @start_date = @workspace.items.minimum(:created_at) || (now - 5.years)
    else            @start_date = now - 7.days
    end

    @end_date = now
    @selected_range = range

    @items = @workspace.items.includes(:reservations, :missing_reports)

    # Count number of days in period
    @days = (@start_date.to_date..@end_date.to_date).to_a
    @num_days = @days.length.to_f


    # =========================================================
    # 1) UTILIZATION TABLE
    # =========================================================
    @utilization = @items.map do |item|
      reservations = item.reservations.where(start_time: @start_date..@end_date)

      if item.start_time && item.end_time
        per_day_blocks = ((item.end_time - item.start_time) / 15.minutes).floor
        total_blocks = per_day_blocks * @num_days
      else
        per_day_blocks = 0
        total_blocks = 0
      end

      reserved_blocks = reservations.sum do |r|
        s = [r.start_time, @start_date].max
        e = [r.end_time,   @end_date].min
        ((e - s) / 15.minutes).ceil
      end

      {
        item: item,
        reserved_blocks: reserved_blocks,
        total_blocks: total_blocks,
        utilization: (total_blocks.zero? ? 0.0 : reserved_blocks / total_blocks)
      }
    end


    # =========================================================
    # 2) HEATMAP (AVERAGE SLOT USAGE)
    # =========================================================
    # 96 time slots per day (every 15 minutes)
    @slots = (0...96).map { |i| i }

    @heatmap = {}

    @items.each do |item|
      # Sum for ALL days
      slot_sums = Array.new(96, 0.0)

      @days.each do |date|
        day_start = date.beginning_of_day
        day_end   = date.end_of_day

        # For this day, fill a daily array
        daily = Array.new(96, 0.0)

        item.reservations
            .where("start_time < ? AND end_time > ?", day_end, day_start)
            .each do |r|
          s = [r.start_time, day_start].max
          e = [r.end_time,   day_end].min

          start_index = ((s - day_start) / 15.minutes).floor
          end_index   = ((e - day_start) / 15.minutes).ceil

          (start_index...end_index).each do |i|
            daily[i] += r.quantity
          end
        end

        # Add to slot_sums
        (0...96).each { |i| slot_sums[i] += daily[i] }
      end

      # Average over number of days
      avg = slot_sums.map { |v| (v / @num_days).round(2) }

      @heatmap[item.id] = avg
    end


    # =========================================================
    # 3) BEHAVIOR METRICS (per item)
    # =========================================================
    now = Time.zone.now

    @behavior = @items.map do |item|
      res = item.reservations.where(start_time: @start_date..@end_date)
      total_res = res.count

      missing = item.missing_reports.where(reported_at: @start_date..@end_date).count

      late = res.select { |r| r.returned_count < r.quantity && r.end_time < now }.count

      {
        item: item,
        total_res: total_res,
        missing_rate: total_res.zero? ? 0.0 : missing.to_f / total_res,
        late_rate:    total_res.zero? ? 0.0 : late.to_f / total_res
      }
    end

    # =========================================================
    # 4) USER ANALYTICS (Top 10 Users)
    # =========================================================

    ranking = params[:user_rank].presence || "frequency"
    @selected_user_rank = ranking

    # Collect all reservations for this workspace in the selected period
    res_scope = Reservation
      .joins(:item)
      .where(items: { workspace_id: @workspace.id })
      .where(start_time: @start_date..@end_date)
      .includes(:user)

    # Build per-user stats
    user_data = {}

    res_scope.each do |r|
      user = r.user
      user_data[user.id] ||= {
        user: user,
        freq: 0,
        recent: nil
      }

      # Frequency = count of reservations
      user_data[user.id][:freq] += 1

      # Recency = most recent reservation end time
      user_data[user.id][:recent] =
        [user_data[user.id][:recent], r.end_time].compact.max
    end

    # Convert hash → array
    user_rows = user_data.values

    # Ranking logic
    @user_rankings =
      case ranking
      when "recency"
        # Most recent first; tiebreak: frequency
        user_rows.sort_by { |d| [-(d[:recent] || Time.at(0)).to_i, -d[:freq]] }
      else # "frequency"
        # Highest frequency first; tiebreak: recency
        user_rows.sort_by { |d| [-d[:freq], -(d[:recent] || Time.at(0)).to_i] }
      end

    @user_rankings = @user_rankings.first(10)

  end

  # --- CSV export methods --- 
  def analytics_utilization_csv
    authorize_owner!
    setup_range_for_csv

    csv = CSV.generate do |csv|
      csv << ["Item", "Reserved Blocks", "Total Blocks", "Utilization (%)"]

      @utilization.each do |u|
        csv << [
          u[:item].name,
          u[:reserved_blocks],
          u[:total_blocks],
          (u[:utilization] * 100).round
        ]
      end
    end

    send_data csv, filename: "workspace_#{@workspace.id}_utilization.csv"
  end

  def analytics_behavior_csv
    authorize_owner!
    setup_range_for_csv

    csv = CSV.generate do |csv|
      csv << ["Item", "Total Reservations", "Missing Rate", "Late Return Rate"]

      @behavior.each do |b|
        csv << [
          b[:item].name,
          b[:total_res],
          (b[:missing_rate] * 100).round,
          (b[:late_rate] * 100).round
        ]
      end
    end

    send_data csv, filename: "workspace_#{@workspace.id}_behavior.csv"
  end

  def analytics_heatmap_csv
    authorize_owner!
    setup_range_for_csv  

    csv = CSV.generate do |csv|
      # Header row: item + time columns
      header = ["Item"] +
        @slots.map { |i| (Time.zone.parse("00:00") + i*15.minutes).strftime("%-I:%M %p") }
      csv << header

      # Each item: one row, one column per time slot
      @items.each do |item|
        row = [item.name] + @heatmap[item.id]
        csv << row
      end
    end

    send_data csv, filename: "workspace_#{@workspace.id}_heatmap.csv"
  end

  private

  def setup_range_for_csv
    analytics # re-run analytics to populate instance vars
  end

  def set_workspace
    @workspace = Workspace.friendly.find(params[:id])
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized." unless current_user_is_owner?(@workspace)
  end

  def workspace_params
    params.require(:workspace).permit(:name, :description, :is_public)
  end

  def ceil_to_15(time)
    sec = (15.minutes - (time.min % 15).minutes) % 15.minutes
    base = time.change(sec: 0)
    sec.zero? ? base : base + sec
  end

  def floor_to_15(time)
    base = time.change(sec: 0)
    base - (time.min % 15).minutes
  end

end
