class WorkspacesController < ApplicationController
  def index
    @workspaces = current_user.workspaces
  end

  def show
    @workspace = current_user.workspaces.find(params[:id])
  end
end