# --- Authentication Steps ---
Given /^a user exists with email "([^"]*)"$/ do |email|
  @user =User.find_or_create_by!(email: email) do |user|
    user.name = email.split('@').first.capitalize
    user.password = "password"
    user.password_confirmation = "password"
    user.email_verified_at = Time.current
  end
end

Given /^I am logged in as a (workspace owner|standard user) of "([^"]*)"$/ do |membership, workspace_name|
  role_name = (membership == "workspace owner") ? "owner" : "user"
  @current_user = User.find_or_create_by!(email: "#{role_name}@example.com") do |user|
    user.name = "#{role_name.capitalize} User"
    user.password = "password"
    user.password_confirmation = "password"
    user.email_verified_at = Time.now
  end

  workspace = Workspace.find_or_create_by!(name: workspace_name)
  UserToWorkspace.find_or_create_by!(
    user: @current_user,
    workspace: workspace,
    role: role_name
  )
  visit path_to('the login page')
  fill_in "session[email]", :with => @current_user.email
  fill_in "session[password]", :with => "password"
  click_button "commit"
end

Given /^"([^"]*)" is a (workspace owner|standard user) of "([^"]*)"$/ do |email, role, workspace_name|
  role_name = (role == "workspace owner") ? "owner" : "user"
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  UserToWorkspace.find_or_create_by!(
    user: user,
    workspace: workspace,
    role: role_name
  )
end

# Logged out
Given('I am logged out') do
  # Try UI logout first
  if page.has_link?("Log Out", wait: 0.2)
    click_link "Log Out"
  elsif page.has_selector?("[data-test='logout']", wait: 0.2)
    find("[data-test='logout']").click
  end

  # If driver is rack-test, hard-clear cookies/session as a fallback
  if page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:clear_cookies)
    page.driver.browser.clear_cookies
  end
  visit path_to('the home page')
end