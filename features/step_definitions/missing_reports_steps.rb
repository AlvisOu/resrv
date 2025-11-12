# --- Givens ---
Given(/^there is an existing missing report for my reservation$/) do
  techlab_workspace = Workspace.find_by(name: "TechLab")
  @reservation.item.update!(workspace: techlab_workspace)
  @reservation.update!(
    quantity: 5,
    returned_count: 3
  )
  missing_qty = @reservation.quantity - @reservation.returned_count.to_i
  
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

# --- Whens ---


# --- Sees ---
Then(/^I should see my reservation in the unresolved reports$/) do
  expect(@reservation).not_to be_nil, "The @reservation variable is not set"
  item_name = @reservation.item.name
  within('div.missing-card:not(.resolved)') do
    expect(page).to have_content(item_name)
    expect(page).to have_content("Reservation: ##{@reservation.id}")
  end
end