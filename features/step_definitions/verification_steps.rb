When("I fill in the verification code for {string}") do |email|
  user = User.find_by!(email: email)
  code = user.verification_code
  fill_in "verification_code", with: code
end