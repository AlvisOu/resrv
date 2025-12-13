Given('the workspace {string} has recent activity for user {string}') do |workspace_name, email|
  workspace = Workspace.find_or_create_by!(name: workspace_name)
  user = User.find_or_create_by!(email: email) do |u|
    u.name = email.split('@').first.capitalize
    u.password = "password"
    u.password_confirmation = "password"
  end

  owner = User.find_or_create_by!(email: "owner@example.com") do |u|
    u.name = "Owner"
    u.password = "password"
    u.password_confirmation = "password"
  end
  UserToWorkspace.find_or_create_by!(user: owner, workspace: workspace, role: "owner")
  UserToWorkspace.find_or_create_by!(user: user, workspace: workspace, role: "user")

  item = Item.find_or_create_by!(name: "Scope", workspace: workspace) do |i|
    i.quantity = 2
    i.start_time = fixed_time.beginning_of_day
    i.end_time   = fixed_time.end_of_day
  end

  Reservation.create!(
    user: user,
    item: item,
    start_time: fixed_time - 1.hour,
    end_time: fixed_time + 1.hour,
    quantity: 1
  )

  Reservation.create!(
    user: user,
    item: item,
    start_time: fixed_time + 2.hours,
    end_time: fixed_time + 3.hours,
    quantity: 1,
    no_show: true
  )
end

When('I visit the user analytics page for workspace {string} and user {string}') do |workspace_name, email|
  workspace = Workspace.find_by!(name: workspace_name)
  user = User.find_by!(email: email)
  visit "/workspaces/#{workspace.slug}/users/#{user.slug}"
end

When('I visit the analytics page for workspace {string}') do |workspace_name|
  workspace = Workspace.find_by!(name: workspace_name)
  visit "/workspaces/#{workspace.slug}/analytics"
end

Given('the workspace {string} has overlapping reservations exceeding capacity') do |workspace_name|
  workspace = Workspace.find_or_create_by!(name: workspace_name)
  item = Item.find_or_create_by!(name: "Rebalance Widget", workspace: workspace) do |i|
    i.quantity = 1
    i.start_time = fixed_time.beginning_of_day
    i.end_time = fixed_time.end_of_day
  end

  user_a = User.find_or_create_by!(email: "rebal_a@example.com") { |u| u.name = "A"; u.password = "password" }
  user_b = User.find_or_create_by!(email: "rebal_b@example.com") { |u| u.name = "B"; u.password = "password" }

  Reservation.create!(
    user: user_a,
    item: item,
    start_time: fixed_time + 30.minutes,
    end_time: fixed_time + 90.minutes,
    quantity: 1
  )

  Reservation.new(
    user: user_b,
    item: item,
    start_time: fixed_time + 30.minutes,
    end_time: fixed_time + 90.minutes,
    quantity: 1
  ).save(validate: false)

  @reservation_count_before = Reservation.count
end

When('I trigger capacity rebalancing for workspace {string}') do |workspace_name|
  workspace = Workspace.find_by!(name: workspace_name)
  item = workspace.items.find_by!(name: "Rebalance Widget")
  ItemCapacityRebalancer.rebalance!(item, tz: Time.zone)
end

Then('one overbooked reservation should be canceled') do
  expect(Reservation.count).to eq(@reservation_count_before - 1)
end

Then('a notification should be recorded for the canceled reservation') do
  expect(Notification.last).not_to be_nil
  expect(Notification.last.message).to include("was canceled")
end

def fixed_time
  @fixed_time ||= Time.zone.parse("2099-01-01 12:00:00")
end

When("I visit the workspace {string} analytics page") do |workspace_name|
  workspace = Workspace.find_by!(name: workspace_name)
  visit analytics_workspace_path(workspace)
end
