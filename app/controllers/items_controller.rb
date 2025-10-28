class ItemsController < ApplicationController
  before_action :set_workspace
  before_action :set_item, only: [:edit, :update]
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
    @workspace = Workspace.find(params[:workspace_id])
    @item = @workspace.items.find(params[:id])
    @item.destroy
    redirect_to workspace_path(@workspace), notice: "Item deleted successfully."
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_item
    @item = @workspace.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :quantity, :start_time, :end_time)
  end

  def require_owner
    membership = @workspace.user_to_workspaces.find_by(user: current_user)
    redirect_to workspace_path(@workspace), alert: "Not authorized." unless membership&.role == 'owner'
    end
end
