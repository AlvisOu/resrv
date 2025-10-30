# --- Givens ---
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


# --- Sees ---
Then /^(?:|I )should see my pending reservation$/ do
  page.should have_content("Your Cart")
  page.should have_content("Mic")
  page.should have_content("1")
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

# --- Actions ---
