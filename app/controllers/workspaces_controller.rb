class WorkspacesController < ApplicationController
  def index
    if params[:query].present?
      query = params[:query]
      @workspaces = Workspace.where(id: query.to_i)
                             .or(Workspace.where("LOWER(name) LIKE ?", "%#{query.downcase}%"))
    else
      @workspaces = current_user.workspaces
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
  end

  private
  def workspace_params
    params.require(:workspace).permit(:name)
  end
end