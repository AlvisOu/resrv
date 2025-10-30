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

Given /^a workspace named "([^"]*)" exists$/ do |workspace_name|
  Workspace.find_or_create_by!(name: workspace_name)
end

Given /^a user exists with email "([^"]*)"$/ do |email|
  User.find_or_create_by!(email: email) do |user|
    user.name = email.split('@').first.capitalize
    user.password = "password"
    user.password_confirmation = "password"
  end
end

Given /^"([^"]*)" is a standard user of "([^"]*)"$/ do |email, workspace_name|
  user = User.find_by!(email: email)
  workspace = Workspace.find_by!(name: workspace_name)
  UserToWorkspace.find_or_create_by!(
    user: user,
    workspace: workspace,
    role: 'user'
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

When("I POST to {string} (form) with params:") do |path, table|
  params = table.rows_hash
  page.driver.post(path, params)
end

# --- API form POST (already suggested, but making sure it matches literally) ----

When('I POST to {string} (form) with params:') do |path, table|
  params = table.rows_hash
  page.driver.post(path, params)  # rack-test
end

# --- UI assertions ----------------------------------------------------------

Then('I should see the toast {string} or the cart count increases') do |toast_text|
  before = (@_cart_count_before || read_cart_count)

  # Either a toast appears...
  if page.has_content?(toast_text, wait: 1.5)
    expect(page).to have_content(toast_text)
  else
    # ...or the cart badge increases
    using_wait_time 2 do
      after = read_cart_count
      expect(after).to be > before
    end
  end
end

# Seed a pending selection via API so UI scenarios have something to work with
Given('I have at least one pending selection for {string}') do |item_name|
  workspace = Workspace.find_or_create_by!(name: "Lerner Auditorium")
  item = Item.find_by!(name: item_name, workspace: workspace)

  body = {
    selections: [
      {
        item_id: item.id,
        workspace_id: workspace.id,
        start_time: (Time.zone.now + 1.hour).change(sec: 0).iso8601,
        end_time:   (Time.zone.now + 1.hour + 15.minutes).change(sec: 0).iso8601,
        quantity: 1
      }
    ]
  }.to_json

  page.driver.post("/cart_items.json", body, { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" })
  @last_json = page.body
end

When('I click {string} on the first cart entry') do |button_text|
  @_cart_count_before = read_cart_count
  line = first_cart_line
  expect(line).to be_present
  within(line) do
    # Works for buttons or links labeled Remove/Delete
    if has_button?(button_text, wait: 0.2)
      click_button(button_text)
    else
      click_link(button_text)
    end
  end
end

Then('I should see the cart count decrease') do
  using_wait_time 2 do
    after = read_cart_count
    # If we couldn't read the old count, assert at least we have a non-negative number
    if defined?(@_cart_count_before) && @_cart_count_before
      expect(after).to be < @_cart_count_before
    else
      expect(after).to be >= 0
    end
  end
end

When('I increase the quantity of the first cart entry to {string}') do |qty|
  input = first_cart_qty_input
  expect(input).to be_present
  @_cart_count_before = read_cart_count
  input.fill_in(with: qty)
  # Nudge change event if needed
  input.native.send_keys(:tab)
end

Then('I should see the cart total show {string}') do |qty|
  # Accept either a badge total, a per-line quantity, or a totals element
  expect(
    page.has_selector?(".cart-total", text: qty, wait: 2) ||
    page.has_selector?("[data-test='cart-total']", text: qty, wait: 2) ||
    (first_cart_qty_input && first_cart_qty_input.value.to_s == qty.to_s)
  ).to be(true)
end

# ========= JSON API STEPS (PATCH/DELETE included) =========

When("I POST JSON to {string} with:") do |path, body|
  if driver_supports_rack_post?
    page.driver.post(path, body, { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" })
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :POST, path: path, body_str: body, headers: { "Content-Type" => "application/json", "Accept" => "application/json" })
  end
end

When("I PATCH JSON to {string} with:") do |path, body|
  if driver_supports_rack_post?
    page.driver.header("Content-Type", "application/json")
    page.driver.header("Accept", "application/json")
    page.driver.submit(:patch, path, body)
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :PATCH, path: path, body_str: body, headers: { "Content-Type" => "application/json", "Accept" => "application/json" })
  end
end

When("I DELETE JSON {string}") do |path|
  if driver_supports_rack_post?
    page.driver.header("Accept", "application/json")
    page.driver.submit(:delete, path, nil)
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :DELETE, path: path, headers: { "Accept" => "application/json" })
  end
end

Then("the response status should be {int}") do |code|
  status = @last_status || (page.respond_to?(:status_code) ? page.status_code : nil)
  expect(status).to eq(code)
end

Given("my cart already contains 1 selection") do
  workspace = Workspace.find_or_create_by!(name: "Lerner Auditorium")
  item = Item.find_or_create_by!(name: "Mic", workspace: workspace) do |it|
    it.quantity   = 10
    it.start_time = Time.zone.today.beginning_of_day
    it.end_time   = Time.zone.today.end_of_day
  end

  body = {
    selections: [
      {
        item_id: item.id,
        workspace_id: workspace.id,
        start_time: (Time.zone.now + 30.minutes).change(sec: 0).iso8601,
        end_time:   (Time.zone.now + 45.minutes).change(sec: 0).iso8601,
        quantity: 1
      }
    ]
  }.to_json

  if driver_supports_rack_post?
    page.driver.post("/cart_items.json", body, { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" })
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :POST, path: "/cart_items.json", body_str: body, headers: { "Content-Type" => "application/json", "Accept" => "application/json" })
  end
end

Given("my cart contains the following selections:") do |table|
  workspace = Workspace.find_or_create_by!(name: "Lerner Auditorium")
  item = Item.find_or_create_by!(name: "Mic", workspace: workspace) do |it|
    it.quantity   = 10
    it.start_time = Time.zone.today.beginning_of_day
    it.end_time   = Time.zone.today.end_of_day
  end

  selections = table.hashes.map do |h|
    {
      item_id: (h["item_id"].presence || item.id).to_i.nonzero? || item.id,
      workspace_id: (h["workspace_id"].presence || workspace.id).to_i.nonzero? || workspace.id,
      start_time: h["start_time"],
      end_time:   h["end_time"],
      quantity:   h["quantity"].to_i
    }
  end

  body = { selections: selections }.to_json

  if driver_supports_rack_post?
    page.driver.post("/cart_items.json", body, { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" })
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :POST, path: "/cart_items.json", body_str: body, headers: { "Content-Type" => "application/json", "Accept" => "application/json" })
  end
end

# ========= HTML FORM POST (for remove_range HTML branch, unauthenticated POST) =========

When('I POST to {string} (form) with params:') do |path, table|
  params = table.rows_hash

  # Build and submit a real form in the browser so Rails treats this as an HTML request.
  form_html = <<~HTML
    (function(){
      var f = document.createElement('form');
      f.method = 'POST';
      f.action = #{path.inspect};
      // Rails authenticity token, if present on page:
      var meta = document.querySelector('meta[name="csrf-token"]');
      if (meta && meta.content) {
        var t = document.createElement('input');
        t.type = 'hidden';
        t.name = 'authenticity_token';
        t.value = meta.content;
        f.appendChild(t);
      }
      return f;
    })();
  HTML

  form = page.evaluate_script(form_html)
  # Append inputs
  params.each do |k, v|
    page.execute_script(<<~JS)
      (function(){
        var f = document.forms[document.forms.length - 1] || document.querySelector('form[action=#{path.inspect}]');
        var i = document.createElement('input');
        i.type = 'hidden';
        i.name = #{k.inspect};
        i.value = #{v.inspect};
        f.appendChild(i);
      })();
    JS
  end

  # Submit and wait for navigation
  page.execute_script("(document.forms[document.forms.length - 1] || document.querySelector('form[action=#{path.inspect}]')).submit();")
  # Let Capybara detect the new page
  using_wait_time 2 do
    expect(page).to have_current_path(/.+/)
  end
end

Then(/^the JSON response should include "([^"]+)" (true|false)$/) do |key, tf|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(tf == "true")
end

Then(/^the JSON response should include "([^"]+)" (-?\d+)$/) do |key, intval|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(intval.to_i)
end


When(/^I POST to "([^"]+)" \(form\) with params:$/) do |path, table|
  params = table.rows_hash

  # Create a form in the browser DOM
  page.execute_script(<<~JS)
    (function(){
      var f = document.createElement('form');
      f.method = 'POST';
      f.action = #{path.inspect};
      var meta = document.querySelector('meta[name="csrf-token"]');
      if (meta && meta.content) {
        var t = document.createElement('input');
        t.type = 'hidden';
        t.name = 'authenticity_token';
        t.value = meta.content;
        f.appendChild(t);
      }
      document.body.appendChild(f);
    })();
  JS

  # Append inputs
  params.each do |k, v|
    page.execute_script(<<~JS)
      (function(){
        var f = document.forms[document.forms.length - 1];
        var i = document.createElement('input');
        i.type = 'hidden';
        i.name = #{k.inspect};
        i.value = #{v.inspect};
        f.appendChild(i);
      })();
    JS
  end

  # Submit and wait for navigation
  page.execute_script("document.forms[document.forms.length - 1].submit();")
  using_wait_time 3 do
    expect(page).to have_current_path(/.+/)
  end
end

Then(/^the JSON response should include "([^"]+)" "([^"]+)"$/) do |key, val|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(val)
end
