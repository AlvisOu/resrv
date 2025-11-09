# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def send_verification_code(user)
    @user = user
    @code = user.verification_code

    mail(
      to: @user.email,
      subject: "Your Verification Code"
    )
  end
end