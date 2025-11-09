class UsersController < ApplicationController
  skip_before_action :require_user, only: [:new, :create]
  
  def new
    @user = User.new
  end

  def show
    @user = current_user
    @workspace_penalties = current_user.penalties
      .active
      .includes(reservation: { item: :workspace })
      .group_by { |p| p.reservation.item.workspace }
  end

  def update
    @user = current_user
    if @user.update(user_params)
      flash[:notice] = "Profile updated successfully."
      redirect_to profile_path
    else
      flash[:notice] = "There was a problem updating your profile."
      redirect_to profile_path
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_verification_email
      session[:unverified_user_id] = @user.id
      flash[:notice] = "Welcome! Please check your email for a verification code."
      redirect_to verify_email_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.owned_workspaces.exists?
      flash[:notice] = "You must delete or transfer ownership of all your workspaces before deleting your account."
      redirect_to profile_path
    else
      current_user.destroy
      reset_session
      flash[:notice] = "Your account has been deleted."
      redirect_to signup_path
    end
  end
  
  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
