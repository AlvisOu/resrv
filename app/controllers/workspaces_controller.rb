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

  def new
    @workspace = Workspace.new
  end
  
  def show
    @current_join = @workspace.user_to_workspaces.find_by(user: current_user)

    @penalty = current_user.penalties.active.find_by(workspace: @workspace)

    @items = @workspace.items.reload.includes(:reservations)

    @day = Date.current
    @tz  = Time.zone || ActiveSupport::TimeZone["UTC"]

    # Precompute the 96 time ticks once for header
    @slots = []
    day_start = @tz.local(@day.year, @day.month, @day.day, 0, 0, 0)
    96.times { |i| @slots << (day_start + i * 15.minutes) }

    # Availability for default quantity = 1 (initial paint)
    @availability_data = @items.map do |item|
      {
        item: item,
        slots: AvailabilityService.new(item, 1, day: @day, tz: @tz).time_slots
      }
    end

    now = @tz.now
    @current_activity = Reservation.joins(:item)
                                   .where(items: { workspace_id: @workspace.id })
                                   .where("reservations.start_time <= ? AND reservations.end_time >= ?", now, now - 30.minutes)
                                   .includes(:user, :item)
                                   .order("reservations.end_time ASC")
  end

  def edit
  end

  def update
    if @workspace.update(workspace_params)
      redirect_to workspace_path(@workspace), notice: "Workspace name updated."
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
    params.require(:workspace).permit(:name)
  end
end