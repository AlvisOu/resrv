Given("a user is created with email {string}") do |email|
  @user = User.create!(
    name: "Test User",
    email: email,
    password: "password",
    password_confirmation: "password"
  )
end

Then("the user's email should be {string}") do |expected_email|
  expect(@user.reload.email).to eq(expected_email)
end

Then("{string} should be blocked from reserving in {string}") do |email, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  expect(user.blocked_from_reserving_in?(workspace)).to be true
end

When("the penalty expires") do
  Penalty.update_all(expires_at: 1.day.ago)
end

Then("{string} should not be blocked from reserving in {string}") do |email, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  expect(user.blocked_from_reserving_in?(workspace)).to be false
end

Given("a penalty exists with reason {string} and appeal state {string}") do |reason, appeal_state|
  user = User.create!(name: "P User", email: "p@example.com", password: "password", password_confirmation: "password")
  workspace = Workspace.create!(name: "P Workspace")
  @penalty = Penalty.create!(
    user: user,
    workspace: workspace,
    reason: reason,
    appeal_state: appeal_state,
    expires_at: 1.day.from_now
  )
end

Then("the penalty should be a late return") do
  expect(@penalty.late_return?).to be true
end

Then("the penalty should not be a no show") do
  expect(@penalty.no_show?).to be false
end

Then("the penalty appeal should be pending") do
  expect(@penalty.appeal_pending?).to be true
end

Then("the penalty should be appealed") do
  expect(@penalty.appealed?).to be true
end

Given("{string} has an expired penalty in {string}") do |email, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  Penalty.create!(
    user: user,
    workspace: workspace,
    reason: "late_return",
    expires_at: 1.day.ago
  )
end

Then("{string} should have {int} active penalty in {string}") do |email, count, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  active_count = user.penalties.active.where(workspace: workspace).count
  expect(active_count).to eq(count)
end
