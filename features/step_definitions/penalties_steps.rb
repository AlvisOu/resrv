Given("a workspace exists with name {string}") do |name|
  Workspace.find_or_create_by!(name: name)
end

Given("I have a pending appeal penalty in {string}") do |workspace_name|
  workspace = Workspace.find_by!(name: workspace_name)
  @penalty = Penalty.create!(
    user: @current_user,
    workspace: workspace,
    reason: "no_show",
    expires_at: 3.days.from_now,
    appeal_state: "pending",
    appeal_message: "Please forgive me"
  )
  # Create notification for owner so it appears in notifications page
  if workspace.owner
    Notification.create!(
      user: workspace.owner,
      penalty: @penalty,
      message: "Appealed penalty in #{workspace.name}"
    )
  end
end

Given("I have a resolved penalty in {string}") do |workspace_name|
  workspace = Workspace.find_by!(name: workspace_name)
  @penalty = Penalty.create!(
    user: @current_user,
    workspace: workspace,
    reason: "no_show",
    expires_at: 3.days.from_now,
    appeal_state: "resolved",
    appeal_resolved_at: Time.current
  )
end

Given("{string} has an active penalty in {string}") do |email, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  @penalty = Penalty.create!(
    user: user,
    workspace: workspace,
    reason: "no_show",
    expires_at: 3.days.from_now,
    appeal_state: "none"
  )
end

Given("{string} has a pending appeal penalty in {string}") do |email, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  @penalty = Penalty.create!(
    user: user,
    workspace: workspace,
    reason: "no_show",
    expires_at: 3.days.from_now,
    appeal_state: "pending",
    appeal_message: "Please forgive me"
  )
  if workspace.owner
    Notification.create!(
      user: workspace.owner,
      penalty: @penalty,
      message: "Appealed penalty in #{workspace.name}"
    )
  end
end

Given("{string} has a resolved penalty in {string}") do |email, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  @penalty = Penalty.create!(
    user: user,
    workspace: workspace,
    reason: "no_show",
    expires_at: 3.days.from_now,
    appeal_state: "resolved",
    appeal_resolved_at: Time.current
  )
end

When("I send a POST request to appeal the penalty") do
  page.driver.submit :post, appeal_penalty_path(@penalty), { appeal_message: "I was sick" }
end

When("I send a POST request to appeal the penalty for {string}") do |email|
  # This step assumes @penalty is set for the user with email
  # But in the scenario, we set @penalty for "owner@example.com"
  # So we just use @penalty
  page.driver.submit :post, appeal_penalty_path(@penalty), { appeal_message: "I was sick" }
end

When("I send a PATCH request to forgive the penalty for {string}") do |email|
  page.driver.submit :patch, forgive_penalty_path(@penalty), {}
end

When("I send a PATCH request to shorten the penalty for {string}") do |email|
  page.driver.submit :patch, shorten_penalty_path(@penalty), { shorten_hours: 24 }
end

Then("the penalty should be pending appeal") do
  expect(@penalty.reload.appeal_state).to eq("pending")
end

Then("{string} should have no penalties in {string}") do |email, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  expect(Penalty.where(user: user, workspace: workspace).count).to eq(0)
end

When("I visit the profile page") do
  visit profile_path
end

When("I visit the notifications page") do
  visit notifications_path
end

Then("the workspace owner should receive a notification about the appeal") do
  owner = @penalty.workspace.owner
  expect(owner.notifications.last.message).to include("appealed a penalty")
end

Then("the user should receive a notification about the penalty removal") do
  user = User.find_by(email: "member@example.com")
  expect(user.notifications.last.message).to include("removed by the workspace owner")
end

Then("the user should receive a notification about the penalty reduction") do
  user = User.find_by(email: "member@example.com")
  expect(user.notifications.last.message).to include("reduced and now expires at")
end
