Given(/^the user "([^"]*)" exists and is unverified with password "([^"]*)"$/) do |email, password|
  User.find_or_create_by!(email: email) do |user|
    user.name = email.split('@').first.capitalize
    user.password = password
    user.password_confirmation = password
    user.email_verified_at = nil
  end
end

When("I fill in the verification code for {string}") do |email|
  user = User.find_by!(email: email)
  code = user.verification_code
  fill_in "verification_code", with: code
end