class PasswordResetsController < ApplicationController
  skip_before_action :require_user

  def new
  end

  def create
    @user = User.find_by(email: params[:email]&.downcase)

    if @user
      # Case 1: User exists AND is verified
      if @user.verified?
        @user.send_password_reset_email
        redirect_to login_path, notice: 'If an account with that email exists, we have sent a password reset link.'
      
      # Case 2: User exists but is NOT verified
      else
        @user.send_verification_email # Send the 6-digit code
        session[:unverified_user_id] = @user.id
        redirect_to verify_email_path, notice: 'Your account is not verified. We sent a new verification code to your email.'
      end
    
    # Case 3: No user found
    else
      # Still show a generic message for security
      redirect_to login_path, notice: 'If an account with that email exists, we have sent a password reset link.'
    end
  end

  def edit
    # 1. Find the user by the token from the URL
    @user = User.find_by(reset_token: params[:token])

    # 2. If no user or token is expired, redirect
    if @user.nil? || @user.reset_sent_at < 15.minutes.ago
      redirect_to new_password_reset_path, alert: 'Password reset link is invalid or has expired.'
    end
  end

  def update
    # 1. Find the user again
    @user = User.find_by(reset_token: params[:token])

    # 2. Check for nil or expired token again
    if @user.nil? || @user.reset_sent_at < 15.minutes.ago
      return redirect_to new_password_reset_path, alert: 'Password reset link is invalid or has expired.'
    end

    # 3. Try to update the password
    if @user.reset_password(params[:password], params[:password_confirmation])
      # 4. Success! Log them in and redirect.
      session[:user_id] = @user.id
      redirect_to root_path, notice: 'Password successfully reset! You are now logged in.'
    else
      # 5. Failed (e.g., password mismatch). Render the 'edit' form again.
      #    The @user object now contains the errors.
      render :edit, status: :unprocessable_entity
    end
  end
end
