class WorkspacesController < ApplicationController
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
  @workspace = Workspace.find(params[:id])
  @current_join = @workspace.user_to_workspaces.find_by(user: current_user)

  @items = @workspace.items.includes(:reservations)

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
end

  private
  def workspace_params
    params.require(:workspace).permit(:name)
  end
end