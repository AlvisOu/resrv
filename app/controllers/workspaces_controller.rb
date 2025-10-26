class WorkspacesController < ApplicationController
  def index
    @workspaces = current_user.workspaces
  end

  def new
    @workspace = Workspace.new
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

  def show
    @workspace = current_user.workspaces.find(params[:id])
  end

  private
  def workspace_params
    params.require(:workspace).permit(:name)
  end
end