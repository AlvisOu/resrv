class UserToWorkspacesController < ApplicationController
  before_action :set_workspace
  
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
    @join_record = @workspace.user_to_workspaces.find_by(user: current_user)

    if @join_record.nil?
      flash[:alert] = "You are not a member of this workspace."
    elsif @join_record.role == 'owner'
      flash[:alert] = "As the owner, you cannot leave your own workspace."
    else
      @join_record.destroy
      flash[:notice] = "You have left #{@workspace.name}."
    end
    redirect_to @workspace
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end
end