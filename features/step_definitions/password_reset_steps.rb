# --- Givens ---
Given('{string} has requested a password reset') do |email|
  @user = User.find_by!(email: email)
  @user.send_password_reset_email
  @user.reload
  expect(@user.reset_token).not_to be_nil
end

Given("that user is not verified") do
  expect(@user).not_to be_nil, "The 'Given a user exists...' step must set @user"
  @user.update_column(:email_verified_at, nil)
end

# --- Actions ---
When('I visit the password reset link from the email') do
  expect(@user).not_to be_nil
  token = @user.reset_token
  expect(token).not_to be_nil
  visit edit_password_reset_path(token: token)
end

When('I visit the password reset link for {string}') do |email|
  @user = User.find_by!(email: email)
  expect(@user).not_to be_nil
  token = @user.reset_token
  expect(token).not_to be_nil
  visit edit_password_reset_path(token: token)
end

When('I visit the password reset page with an invalid token {string}') do |token|
  visit edit_password_reset_path(token: token)
end

# --- Sees ---
Then('an email should be sent to {string}') do |email|
  sent_email = ActionMailer::Base.deliveries.last
  expect(sent_email).not_to be_nil
  expect(sent_email.to).to include(email)
end

Then("no email should be sent") do
  expect(ActionMailer::Base.deliveries).to be_empty
end

Given("15 minutes have passed") do
  travel(16.minutes)
end