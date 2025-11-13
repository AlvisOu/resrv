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

# features/step_definitions/reservation_steps.rb
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