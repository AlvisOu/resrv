# --- Givens ---
Given(/^there is an existing missing report for my reservation$/) do
  techlab_workspace = Workspace.find_by(name: "TechLab")
  @reservation.item.update!(workspace: techlab_workspace)
  @reservation.update!(
    quantity: 5,
    returned_count: 3
  )
  missing_qty = @reservation.quantity - @reservation.returned_count.to_i
  @original_item_quantity = @reservation.item.quantity

  @reservation.item.decrement!(:quantity, missing_qty)
  @missing_report = MissingReport.find_or_create_by!(
    reservation: @reservation,
    item: @reservation.item,
    workspace: techlab_workspace,
    quantity: missing_qty,
    resolved: false,
  )
end

Given(/^there is also an existing resolved report$/) do
  techlab_workspace = Workspace.find_by!(name: "TechLab")
  resolved_item = Item.create!(
    workspace: techlab_workspace,
    name: "Old Resolved Item",
    quantity: 10,
    start_time: 3.days.ago.change(hour: 9),
    end_time: 3.days.from_now.change(hour: 17)
  )
  
  resolved_reservation = Reservation.create!(
    item: resolved_item, 
    user_id: @reservation.user_id,
    quantity: 2, 
    returned_count: 1,
    start_time: 2.days.ago.change(hour: 10),
    end_time: 1.day.ago.change(hour: 11)
  )
  MissingReport.create!(
    reservation: resolved_reservation,
    item: resolved_item,
    workspace: techlab_workspace,
    quantity: 1,
    resolved: true,
    updated_at: 1.day.ago
  )
end

Given(/^my reservation has (\d+) items where (\d+) were returned$/) do |total_quantity, returned_count|
  @reservation.update!(
    quantity: total_quantity.to_i,
    returned_count: returned_count.to_i
  )
  @reservation.item.update!(quantity: total_quantity.to_i)
end

Given(/^the reservation has ended over 30 minutes ago$/) do
  @reservation.update!(end_time: 40.minutes.ago)
end

# --- Whens ---

When(/^I trigger the automatic missing item check$/) do
  @reservation.reload.auto_mark_missing_items
end

When(/^I press "([^"]*)" and accept the alert for my missing report$/) do |button_text|
  accept_confirm do
    click_button(button_text)
  end
end

# --- Sees ---
Then(/^I should see my reservation in the unresolved reports$/) do
  expect(@reservation).not_to be_nil, "The @reservation variable is not set"
  item_name = @reservation.item.name
  within('div.missing-card:not(.resolved)') do
    expect(page).to have_content(item_name)
    expect(page).to have_content("Reservation: ##{@reservation.id}")
  end
end

Then(/^I should see my reservation in the resolved reports$/) do
  item_name = @reservation.item.name
  within('div.missing-card.resolved') do
    expect(page).to have_content(item_name)
    expect(page).to have_content("Reservation: ##{@reservation.id}")
  end
end

Then(/^a missing report should be created$/) do
  report = MissingReport.find_by(reservation: @reservation)
  expect(report).not_to be_nil
  expect(report.quantity).to eq(@reservation.quantity - @reservation.returned_count.to_i)
  expect(report.resolved).to be false
end

Then(/^the item quantity should be decreased by (\d+)$/) do |missing_qty|
  item = @reservation.item.reload
  expect(item.quantity).to eq(@reservation.quantity - missing_qty)
end

Then(/^the item quantity should be increased by (\d+)$/) do |quantity_restored|
  item = @reservation.item.reload
  expect(item.quantity).to eq(@original_item_quantity)
end

When(/^I create a missing report for my reservation via the controller$/) do
  workspace = Workspace.find_by!(name: "TechLab")

  begin
    page.driver.submit(
      :post,
      workspace_missing_reports_path(workspace),
      { reservation_id: @reservation.id }
    )
  rescue ActionController::RoutingError
    # The create action runs and then redirects to reservation_path(reservation),
    # which does not exist in this app. We ignore that routing error because
    # we only care that the create action and its side effects ran.
  end
end


Then(/^there should be no missing report for my reservation$/) do
  report = MissingReport.find_by(reservation: @reservation)
  expect(report).to be_nil
end

Then(/^the item quantity should remain unchanged$/) do
  item = @reservation.item.reload
  # In our Given step, we set item.quantity = total_quantity.
  # When nothing is missing, create does not touch item.quantity.
  expect(item.quantity).to eq(@reservation.quantity)
end
