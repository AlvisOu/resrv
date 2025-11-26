# --- Sees ---
Then /^(?:|I )the "([^"]*)" item details should be updated$/ do |original_item_name|
  expect(page).to have_content(@new_item_name)
  unless @new_item_name.include?(original_item_name)
    expect(page).not_to have_content(original_item_name)
  end
end

# --- Actions ---
When /^(?:|I )fill in the name "([^"]*)", start time, end time, and quantity$/ do |item_name|
  fill_in "item[name]", with: item_name
  fill_in "item[quantity]", with: "10"

  select "00", from: "item_start_time_4i"  # hour
  select "00", from: "item_start_time_5i"  # minute
  select "01", from: "item_end_time_4i"    # hour
  select "00", from: "item_end_time_5i"    # minute
end
When(/^(?:|I )change the name, start time, end time, and quantity$/) do
  @new_item_name = "Updated Mic"
  @new_quantity = "5"
  fill_in "item[name]", with: @new_item_name
  fill_in "item[quantity]", with: @new_quantity

  select "09", from: "item_start_time_4i" # Hour
  select "30", from: "item_start_time_5i" # Minute
  select "17", from: "item_end_time_4i"
  select "00", from: "item_end_time_5i"
end