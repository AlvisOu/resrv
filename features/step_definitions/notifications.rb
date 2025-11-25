# --- Givens ---
Given("I have {int} unread notifications: {string} and {string}") do |count, title1, title2|
    @current_user.notifications.destroy_all

    workspace = Workspace.first || Workspace.create!(name: "Test Workspace")
  item = Item.first || Item.create!(
    name: "Test Item", 
    quantity: 10, 
    workspace: workspace,
    start_time: Time.zone.now.beginning_of_day + 9.hours,
    end_time: Time.zone.now.beginning_of_day + 17.hours
  )

  base_time = Time.zone.now.beginning_of_day + 10.hours
  
  reservation1 = Reservation.create!(
    user: @current_user,
    item: item,
    start_time: base_time + 1.hour,
    end_time: base_time + 2.hours,
    in_cart: false
  )
  
  reservation2 = Reservation.create!(
    user: @current_user,
    item: item,
    start_time: base_time + 3.hours,
    end_time: base_time + 4.hours,
    in_cart: false
  )
  
  # Create notifications with reservations
  @current_user.notifications.create!(
    message: title1, 
    read: false,
    reservation: reservation1
  )
  @current_user.notifications.create!(
    message: title2, 
    read: false,
    reservation: reservation2
  )
    expect(@current_user.notifications.unread.count).to eq(count)
end


# --- Whens ---
When("I click {string} for {string}") do |button_text, notification_message|
    notification_text_element = find('strong', text: notification_message)
    notification_block = notification_text_element.find(:xpath, '..')
    within(notification_block) do
        click_button(button_text)
    end
end

When("I press {string} for {string} and accept the alert") do |button_text, notification_message|
  notification_text_element = find('strong', text: notification_message)
  notification_block = notification_text_element.find(:xpath, '..')

  within(notification_block) do
    accept_alert do
      click_button(button_text)
    end
  end
end


# --- Sees ---
Then("I should see an unread count of {string}") do |count|
    if count == "0"
        expect(page).to have_no_selector('#unread-count')
    else
        count_element = find('#unread-count')
        expect(count_element).to have_content(count)
    end
end

Then("the {string} notification should be marked as read") do |notification_message|
    notification_text_element = find('strong', text: notification_message)
    notification_block = notification_text_element.find(:xpath, '..')
    expect(notification_block).to have_no_button('Mark as Read')
end

Then("all notifications should be marked as read") do
  expect(page).to have_no_button("Mark as Read")
end

Given("a pending penalty appeal notification exists for {string}") do |workspace_name|
  workspace = Workspace.find_or_create_by!(name: workspace_name)
  member = User.find_or_create_by!(email: "appeal_member@example.com") do |u|
    u.name = "Appeal Member"
    u.password = "password"
    u.email_verified_at = Time.current
  end

  penalty = Penalty.create!(
    user: member,
    workspace: workspace,
    reason: "no_show",
    expires_at: 3.days.from_now,
    appeal_state: "pending",
    appeal_message: "Please reconsider"
  )

  Notification.create!(
    user: @current_user,
    penalty: penalty,
    message: "Appealed penalty in #{workspace.name}"
  )
end

Given("I have an active penalty in {string}") do |workspace_name|
  workspace = Workspace.find_or_create_by!(name: workspace_name)
  Penalty.create!(
    user: @current_user,
    workspace: workspace,
    reason: "no_show",
    expires_at: 3.days.from_now
  )
end
