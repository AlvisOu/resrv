class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  # Set the current user based on the session
  before_action :require_user
  helper_method :current_user, :logged_in?, :current_user_is_owner?

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !current_user.nil?
  end

  def current_user_is_owner?(workspace)
    join = workspace.user_to_workspaces.find_by(user: current_user)
    join && join.role == "owner"
  end

  def require_user
    unless logged_in?
      flash[:alert] = "You must be logged in to access that page."
      redirect_to login_path
    end
  end
end
