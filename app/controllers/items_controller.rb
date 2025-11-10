class ItemsController < ApplicationController
  before_action :set_workspace
  before_action :set_item, only: [:edit, :update, :destroy]
  before_action :require_owner

  # GET /workspaces/:workspace_id/items/new
  def new
    @item = @workspace.items.build
  end

  # POST /workspaces/:workspace_id/items
  def create
    @item = @workspace.items.build(item_params)
    if @item.save
      redirect_to workspace_path(@workspace), notice: "Item added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /workspaces/:workspace_id/items/:id/edit
  def edit
    today = Time.zone.today
    weekday = today.wday

    # Hourly reservations today
    today_res = @item.reservations.where(start_time: today.beginning_of_day..today.end_of_day)
    @current_counts = today_res.group_by { |r| r.start_time.hour }.transform_values(&:count)

    # Historical averages: same weekday over past month
    start_range = 1.month.ago.beginning_of_day
    past_res = @item.reservations.where(start_time: start_range..Time.zone.now)
    same_wday_res = past_res.select { |r| r.start_time.wday == weekday }
    grouped = same_wday_res.group_by { |r| r.start_time.hour }

    @avg_counts = grouped.transform_values { |rs| (rs.count.to_f / 4.0).round(2) }
    @hours = (0..23).to_a
    @total_quantity = @item.quantity

    # Busyness index
    avg_today = @avg_counts.values.sum / (@avg_counts.size.nonzero? || 1)
    curr_today = @current_counts.values.sum / (@current_counts.size.nonzero? || 1)
    @busyness_index = (curr_today / (avg_today.nonzero? || 1) * 100).round
  end


  # PATCH/PUT /workspaces/:workspace_id/items/:id
  def update
    if @item.update(item_params)
      redirect_to workspace_path(@workspace), notice: "Item updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workspace = Workspace.friendly.find(params[:workspace_id])
    @item = @workspace.items.friendly.find(params[:id])
    @item.destroy
    redirect_to workspace_path(@workspace), notice: "Item deleted successfully."
  end

  private

  def set_workspace
    @workspace = Workspace.friendly.find(params[:workspace_id])
  end

  def set_item
    @item = @workspace.items.friendly.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :quantity, :start_time, :end_time)
  end

  def require_owner
    membership = @workspace.user_to_workspaces.find_by(user: current_user)
    redirect_to workspace_path(@workspace), alert: "Not authorized." unless membership&.role == 'owner'
    end
end
