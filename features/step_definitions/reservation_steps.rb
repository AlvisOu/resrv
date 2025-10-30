# --- Givens ---
Given /^(?:|I )have an existing reservation$/ do
  # This step creates prerequisite data in the database.
  # It assumes @current_user is set from the "logged in" step.
  # Assumes Workspace, Item, and Reservation models.
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
      start_time: today.noon + 2.hours,
      end_time:   today.noon + 3.hours
    )
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

When /^(?:|I )press the time slot "([^"]*)"$/ do |slot_title|
  # Deterministic time slot
  within ".schedule-grid" do
    find("div.slot[title='#{slot_title}']").click
  end
end

When /^(?:|I )click "cancel" on the reservation$/ do
  # This needs to find the specific reservation (created in the Given step)
  # and click a "cancel" button *within* its row/element.
  # Assumes the reservation element has an ID like "reservation_123".
  reservation_element = find("#reservation_#{@reservation.id}")
  within(reservation_element) do
    click_button "cancel" # Or click_link "cancel"
  end
end

When(/^I click "cancel" on the reservation for "(.+)"$/) do |item_name|
  within(:xpath, "//tr[td[contains(text(), '#{item_name}')]]") do
    click_link("Cancel")
  end
end