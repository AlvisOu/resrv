class UserToWorkspacesController < ApplicationController
  before_action :set_workspace
  before_action :set_current_join, only: [:destroy]
  
  def create
    if @workspace.users.include?(current_user)
      flash[:alert] = "You are already a member of this workspace."
    else
      @workspace.user_to_workspaces.create(user: current_user, role: 'user')
      flash[:notice] = "You have successfully joined #{@workspace.name}!"
    end
    redirect_to @workspace
  end

  def destroy
    if @current_join.nil?
      flash[:alert] = "You are not a member of this workspace."
      return redirect_to @workspace
    end

    if @current_join.role == 'owner'
      @workspace.destroy
      flash[:notice] = "Workspace '#{@workspace.name}' was permanently deleted."
      redirect_to root_path
    else
      # 'Users' just destroy their own join record (they leave)
      @current_join.destroy
      flash[:notice] = "You have left #{@workspace.name}."
      redirect_to @workspace
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_current_join
    @current_join = @workspace.user_to_workspaces.find_by(user: current_user)
  end
end