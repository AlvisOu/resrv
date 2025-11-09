class SessionsController < ApplicationController
  skip_before_action :require_user, only: [:new, :create]
  
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user&.authenticate(params[:session][:password])
      if user.verified?
        session[:user_id] = user.id
        flash[:notice] = "Logged in successfully."
        redirect_to root_path
      else
        user.send_verification_email
        session[:unverified_user_id] = user.id
        flash[:notice] = "Please verify your email to continue."
        redirect_to verify_email_path
      end
    else
      flash[:notice] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Logged out successfully."
    redirect_to login_path
  end
end
