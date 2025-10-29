require 'uri'
require 'cgi'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "selectors"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(*selector_for(locator)) { yield } : yield
  end
end
World(WithinHelpers)

# Single-line step scoper
When /^(.*) within (.*[^:])$/ do |step, parent|
  with_scope(parent) { When step }
end

# Multi-line step scoper
When /^(.*) within (.*[^:]):$/ do |step, parent, table_or_string|
  with_scope(parent) { When "#{step}:", table_or_string }
end

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )press "([^"]*)"$/ do |button|
  click_button(button)
end

When /^(?:|I )click "([^"]*)"$/ do |button_or_link|
  click_on(button_or_link)
end

When /^(?:|I )follow "([^"]*)"$/ do |link|
  click_link(link)
end

When /^(?:|I )fill in "([^"]*)" with "([^"]*)"$/ do |field, value|
  fill_in(field, :with => value)
end

When /^(?:|I )fill in "([^"]*)" for "([^"]*)"$/ do |value, field|
  fill_in(field, :with => value)
end

When /^(?:|I )fill in the following:$/ do |fields|
  fields.rows_hash.each do |name, value|
    When %{I fill in "#{name}" with "#{value}"}
  end
end

When /^(?:|I )select "([^"]*)" from "([^"]*)"$/ do |value, field|
  select(value, :from => field)
end

When /^(?:|I )check "([^"]*)"$/ do |field|
  check(field)
end

When /^(?:|I )uncheck "([^"]*)"$/ do |field|
  uncheck(field)
end

When /^(?:|I )choose "([^"]*)"$/ do |field|
  choose(field)
end

When /^(?:|I )attach the file "([^"]*)" to "([^"]*)"$/ do |path, field|
  attach_file(field, File.expand_path(path))
end

Then /^(?:|I )should see "([^"]*)"$/ do |text|
  if page.respond_to? :should
    page.should have_content(text)
  else
    assert page.has_content?(text)
  end
end

Then /^(?:|I )should see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)

  if page.respond_to? :should
    page.should have_xpath('//*', :text => regexp)
  else
    assert page.has_xpath?('//*', :text => regexp)
  end
end

Then(/^I should see the text "(.*?)"$/) do |text|
  expect(page).to have_content(text)
end

Then /^(?:|I )should not see "([^"]*)"$/ do |text|
  if page.respond_to? :should
    page.should have_no_content(text)
  else
    assert page.has_no_content?(text)
  end
end

Then /^(?:|I )should not see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)

  if page.respond_to? :should
    page.should have_no_xpath('//*', :text => regexp)
  else
    assert page.has_no_xpath?('//*', :text => regexp)
  end
end

Then /^the "([^"]*)" field(?: within (.*))? should contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field = find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    if field_value.respond_to? :should
      field_value.should =~ /#{value}/
    else
      assert_match(/#{value}/, field_value)
    end
  end
end

Then /^the "([^"]*)" field(?: within (.*))? should not contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field = find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    if field_value.respond_to? :should_not
      field_value.should_not =~ /#{value}/
    else
      assert_no_match(/#{value}/, field_value)
    end
  end
end

Then /^the "([^"]*)" field should have the error "([^"]*)"$/ do |field, error_message|
  element = find_field(field)
  classes = element.find(:xpath, '..')[:class].split(' ')

  form_for_input = element.find(:xpath, 'ancestor::form[1]')
  using_formtastic = form_for_input[:class].include?('formtastic')
  error_class = using_formtastic ? 'error' : 'field_with_errors'

  if classes.respond_to? :should
    classes.should include(error_class)
  else
    assert classes.include?(error_class)
  end

  if page.respond_to?(:should)
    if using_formtastic
      error_paragraph = element.find(:xpath, '../*[@class="inline-errors"][1]')
      error_paragraph.should have_content(error_message)
    else
      page.should have_content("#{field.titlecase} #{error_message}")
    end
  else
    if using_formtastic
      error_paragraph = element.find(:xpath, '../*[@class="inline-errors"][1]')
      assert error_paragraph.has_content?(error_message)
    else
      assert page.has_content?("#{field.titlecase} #{error_message}")
    end
  end
end

Then /^the "([^"]*)" field should have no error$/ do |field|
  element = find_field(field)
  classes = element.find(:xpath, '..')[:class].split(' ')
  if classes.respond_to? :should
    classes.should_not include('field_with_errors')
    classes.should_not include('error')
  else
    assert !classes.include?('field_with_errors')
    assert !classes.include?('error')
  end
end

Then /^the "([^"]*)" checkbox(?: within (.*))? should be checked$/ do |label, parent|
  with_scope(parent) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      field_checked.should be_true
    else
      assert field_checked
    end
  end
end

Then /^the "([^"]*)" checkbox(?: within (.*))? should not be checked$/ do |label, parent|
  with_scope(parent) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      field_checked.should be_false
    else
      assert !field_checked
    end
  end
end
 
Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  if current_path.respond_to? :should
    current_path.should == path_to(page_name)
  else
    assert_equal path_to(page_name), current_path
  end
end

Then /^(?:|I )should have the following query string:$/ do |expected_pairs|
  query = URI.parse(current_url).query
  actual_params = query ? CGI.parse(query) : {}
  expected_params = {}
  expected_pairs.rows_hash.each_pair{|k,v| expected_params[k] = v.split(',')} 
  
  if actual_params.respond_to? :should
    actual_params.should == expected_params
  else
    assert_equal expected_params, actual_params
  end
end

Then /^show me the page$/ do
  save_and_open_page
end

# Custom steps for workflow features
# DONE
Given /^I am logged in as a (workspace owner|standard user) of "([^"]*)"$/ do |membership, workspace_name|
  role_name = (membership == "workspace owner") ? "owner" : "user"
  @current_user = User.find_or_create_by!(email: "#{role_name}@example.com") do |user|
    user.name = "#{role_name.capitalize} User"
    user.password = "password"
    user.password_confirmation = "password"
  end

  workspace = Workspace.find_or_create_by!(name: workspace_name)
  UserToWorkspace.find_or_create_by!(
    user: @current_user,
    workspace: workspace,
    role: role_name
  )
  visit path_to('the login page')
  fill_in "session[email]", :with => @current_user.email
  fill_in "session[password]", :with => "password"
  click_button "commit"
end

Given /^a workspace item named "([^"]*)" with availability exists in "([^"]*)"$/ do |item_name, workspace_name|
  workspace = Workspace.find_by!(name: workspace_name)
  Item.create!(
    name: item_name,
    start_time: Time.zone.local(2000,1,1,0,0),
    end_time: Time.zone.local(2000,1,1,23,45),
    quantity: 10,
    workspace: workspace
  )
end

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

When /^(?:|I )fill in the workspace information$/ do
  # This is a declarative step. We fill in concrete data for the test.
  @workspace_name = "My New Test Workspace" # Store for later assertion
  fill_in("workspace[name]", with: @workspace_name)
  # Add other fields as necessary
end

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

When /^(?:|I )press "([^"]*)" to edit it$/ do |item_name|
  # This step assumes the item's name itself is a link to edit it.
  click_link(item_name)
  # If the edit button is separate, you might need a more complex selector:
  # find(:xpath, "//*[contains(text(),'#{item_name}')]/ancestor::div[@class='item-row']//a[text()='Edit']").click
end

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

When /^(?:|I )press "([^"]*)" and accept the alert$/ do |button_name|
  accept_alert do
    click_button(button_name)
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

Then /^(?:|I )should see a "([^"]*)"$/ do |selector_name|
  # This asserts that an element (like a form) is present.
  # Requires a mapping in features/support/selectors.rb
  # e.g., add to selectors.rb:
  #   'Create Workspace Form' => '#create-workspace-form'
  page.should have_selector(*selector_for(selector_name))
end

Then /^(?:|I )the new workspace should appear in my list of workspaces$/ do
  # Assumes @workspace_name was stored in the "fill in" step.
  page.should have_content(@workspace_name)
end

Then /^(?:|I )should see "([^"]*)" in the "([^"]*)" workspace$/ do |item_name, workspace_name|
  # This confirms we're on the right page and the item is visible.
  page.should have_content(workspace_name) # e.g., in a heading
  page.should have_content(item_name)     # e.g., in the item list
end

Then /^(?:|I )should see "([^"]*)" and its availabilities$/ do |item_name|
  using_wait_time 3 do
    expect(page).to have_content(item_name)
  end
  expect(page).to have_selector(".schedule-grid")
end

Then /^(?:|I )the "([^"]*)" item details should be updated$/ do |original_item_name|
  expect(page).to have_content(@new_item_name)
  expect(page).to have_content(@new_quantity)
  unless @new_item_name.include?(original_item_name)
    expect(page).not_to have_content(original_item_name)
  end
end

Then /^(?:|I )should not see "([^"]*)" in the "([^"]*)" workspace$/ do |item_name, workspace_name|
  # Verify we're still on the correct workspace page
  page.should have_content(workspace_name)
  # Verify the item is gone
  page.should have_no_content(item_name)
end

Then /^(?:|I )should see my pending reservation$/ do
  # This is likely on a "Cart" or "Checkout" page.
  page.should have_content("Your Cart")
  page.should have_content("Mic")
  page.should have_content("1")
end

Then /^(?:|I )should see the new reservation for "([^"]*)"$/ do |item_name|
  # This is on the "My Reservation" page.
  page.should have_content("My Reservations") # Page title
  page.should have_content(item_name)
end

Then /^(?:|I )should see all my reservations$/ do
  # This step should find the reservation created in the 'Given' step.
  page.should have_selector("#reservation_#{@reservation.id}")
  page.should have_content(@reservation.item.name)
end

When(/^I click "cancel" on the reservation for "(.+)"$/) do |item_name|
  within(:xpath, "//tr[td[contains(text(), '#{item_name}')]]") do
    click_link("Cancel")
  end
end

Then(/^I should not see the reservation for "(.+)"$/) do |item_name|
  expect(page).not_to have_content(item_name)
end

Then(/^(?:|I )should see a confirmation message$/) do
  expect(page).to have_content("Reservation canceled successfully.")
end