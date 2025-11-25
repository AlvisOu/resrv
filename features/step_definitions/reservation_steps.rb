# --- Givens ---
Given /^(?:|I )have an existing reservation$/ do
    today = Time.zone.today
    workspace = Workspace.find_or_create_by!(name: "Lerner Auditorium")
    item = Item.find_or_create_by!(
      name: "Mic",
      workspace: workspace,
      quantity: 5,
      start_time: today.beginning_of_day + 6.hours,
      end_time:   today.beginning_of_day + 23.hours
    )

    @reservation = Reservation.create!(
      user: @current_user,
      item: item,
      start_time: (today + 1.day).beginning_of_day + 14.hours,
      end_time:   (today + 1.day).beginning_of_day + 15.hours
    )
end
Given(/^I have a reservation in "([^"]*)" for "([^"]*)"$/) do |workspace_name, item_name|
  workspace = Workspace.find_by!(name: workspace_name)
  item = Item.find_by!(name: item_name, workspace: workspace)
  user = User.find_or_create_by!(email: "user@example.com") do |u|
    u.name = "Example User"
    u.password = "password"
  end

  @reservation = Reservation.create!(
    user: user,
    item: item,
    start_time: 2.hours.ago,
    end_time: 1.hour.ago,
    quantity: 1,
    returned_count: 0
  )
end
Given(/^I have a reservation in "([^"]*)" for "([^"]*)" with (\d+) reserved items$/) do |workspace_name, item_name, quantity|
  workspace = Workspace.find_by!(name: workspace_name)
  item = Item.find_by!(name: item_name, workspace: workspace)
  user = User.find_or_create_by!(email: "user@example.com") do |u|
    u.name = "Example User"
    u.password = "password"
  end

  @reservation = Reservation.create!(
    user: user,
    item: item,
    start_time: 2.hours.ago,
    end_time: 1.hour.ago,
    quantity: quantity.to_i,
    returned_count: 0
  )
end

Given("another user's reservation exists in {string} for {string}") do |workspace_name, item_name|
  workspace = Workspace.find_or_create_by!(name: workspace_name)
  item = Item.find_or_create_by!(
    name: item_name,
    workspace: workspace,
    quantity: 5,
    start_time: Time.zone.now.beginning_of_day + 8.hours,
    end_time: Time.zone.now.beginning_of_day + 22.hours
  )
  user = User.find_or_create_by!(email: "member@example.com") do |u|
    u.name = "Member User"
    u.password = "password"
    u.email_verified_at = Time.current
  end

  @reservation = Reservation.create!(
    user: user,
    item: item,
    start_time: Time.zone.now + 2.hours,
    end_time: Time.zone.now + 3.hours,
    quantity: 1
  )
end

When("I visit that reservation page") do
  visit reservation_path(@reservation)
end

# --- Sees ---
Then /^(?:|I )should see the new reservation for "([^"]*)"$/ do |item_name|
  page.should have_content("My Reservations")
  page.should have_content(item_name)
end
Then /^(?:|I )should see all my reservations$/ do
  page.should have_selector("#reservation_#{@reservation.id}")
  page.should have_content(@reservation.item.name)
end
Then(/^I should not see the reservation for "(.+)"$/) do |item_name|
  expect(page).not_to have_content(item_name)
end

# --- Actions ---
When /^(?:|I )adjust the quantity for "([^"]*)"$/ do |item_name|
  qty_wrap = find(:xpath, "//div[contains(@class,'item-name') and normalize-space(text())='#{item_name}']/following-sibling::div[contains(@class,'sticky-2')]//div[contains(@class,'qty-wrap')]")
  qty_wrap.find(".qty-up").click
end
When(/^I press an available time slot for "([^"]+)"$/) do |item_name|
  item = Item.find_by!(name: item_name)
  slot = find(%(.slot.available[data-item-id="#{item.id}"]), match: :first, wait: 5)
  slot.click
  expect(slot[:class]).to include("selected")
end
When(/^I click "cancel" on the reservation for "(.+)"$/) do |item_name|
  within(:xpath, "//tr[td[contains(text(), '#{item_name}')]]") do
    click_link("Cancel")
  end
end
When(/^I mark the reservation as a no-show$/) do
  page.driver.submit :patch, mark_no_show_reservation_path(@reservation), {}
end
When(/^I return (\d+) items from the reservation$/) do |qty|
  page.driver.submit :patch,
    return_items_reservation_path(@reservation),
    { quantity_to_return: qty.to_i }
end
When(/^I undo return of (\d+) items from the reservation$/) do |qty|
  page.driver.submit :patch,
    undo_return_items_reservation_path(@reservation),
    { quantity_to_undo: qty.to_i }
end
