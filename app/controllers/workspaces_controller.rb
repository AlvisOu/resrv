class WorkspacesController < ApplicationController
  before_action :set_workspace, only: [:show, :edit, :update]
  before_action :authorize_owner!, only: [:edit, :update]

  def index
    if params[:query].present?
      query = params[:query]
      @workspaces = Workspace.where(id: query.to_i)
                             .or(Workspace.where("LOWER(name) LIKE ?", "%#{query.downcase}%"))
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
                                
    @current_activity.each do |reservation|
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

  private

  def set_workspace
    @workspace = Workspace.friendly.find(params[:id])
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized." unless current_user_is_owner?(@workspace)
  end

  def workspace_params
    params.require(:workspace).permit(:name, :description)
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
