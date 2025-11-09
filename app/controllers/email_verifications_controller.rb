class EmailVerificationsController < ApplicationController
  skip_before_action :require_user, only: [:new, :create]
  before_action :find_user

  def new
  end

  def create
    submitted_code = params[:verification_code]
    if @user.verify_email_code(submitted_code)
      session.delete(:unverified_user_id)
      session[:user_id] = @user.id
      flash[:notice] = "Email verified successfully. You are now logged in."
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid verification code. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def find_user
    @user = User.find_by(id: session[:unverified_user_id])
    # If no user is found, redirect them to the signup page.
    unless @user
      redirect_to new_user_path, alert: 'Invalid session. Please sign up again.'
    end
  end
end
