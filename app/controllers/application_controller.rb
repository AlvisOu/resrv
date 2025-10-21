class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  # Set the current user based on the session
  before_action :set_current_user
  helper_method :current_user, :logged_in?

  def set_current_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    end
  end

  def current_user
    @current_user
  end

  def logged_in?
    !current_user.nil?
  end
end
