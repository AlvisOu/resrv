Given(/^a complete reservation exists$/) do
  # 1. Create the user
  @user = User.create!(
    name: "Test User",
    email: "test-#{SecureRandom.hex(4)}@example.com",
    password: "password"
  )
  
  # 2. Create the workspace
  @workspace = Workspace.create!(name: "Test Workspace")

  # 3. Create the item
  @item = Item.create!(
    name: "Test Item",
    workspace: @workspace,
    quantity: 5,
    start_time: 1.day.ago.change(hour: 9),
    end_time: 1.day.from_now.change(hour: 17)
  )

  # 4. Create the reservation and store it
  @reservation = Reservation.create!(
    user: @user,
    item: @item,
    quantity: 1,
    start_time: 1.day.ago.change(hour: 10),
    end_time: 1.day.from_now.change(hour: 11)
  )
end

When(/^the "([^"]*)" reminder job runs for my reservation$/) do |reminder_type|
  expect(@reservation).not_to be_nil, "The @reservation variable is not set."
  ReservationReminderJob.perform_now(@reservation.id, reminder_type)
end

When(/^the reminder job runs for a non-existent reservation$/) do
  non_existent_id = (Reservation.maximum(:id) || 0) + 99
  ReservationReminderJob.perform_now(non_existent_id, 'start')
end

Then(/^I should have (\d+) notification(?:s?)$/) do |count|
  expect(Notification.count).to eq(count.to_i)
end

Then(/^the notification message should contain "([^"]*)"$/) do |message_content|
  notification = Notification.last
  expect(notification).not_to be_nil
  expect(notification.message).to include(message_content)
end