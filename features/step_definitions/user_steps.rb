# --- User exists ---
Given /^a user exists with email "([^"]*)"$/ do |email|
  User.find_or_create_by!(email: email) do |user|
    user.name = email.split('@').first.capitalize
    user.password = "password"
    user.password_confirmation = "password"
  end
end

# --- User role in workspace ---
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
