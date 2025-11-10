# --- Givens ---
Given("I have {int} unread notifications: {string} and {string}") do |count, title1, title2|
    @current_user.notifications.destroy_all
    @current_user.notifications.create!(message: title1, read: false)
    @current_user.notifications.create!(message: title2, read: false)
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