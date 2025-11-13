# --- Givens ---
Given("my cart already contains 1 selection") do
  workspace = Workspace.find_or_create_by!(name: "Lerner Auditorium")
  item = Item.find_or_create_by!(name: "Mic", workspace: workspace) do |it|
    it.quantity   = 10
    it.start_time = Time.zone.today.beginning_of_day
    it.end_time   = Time.zone.today.end_of_day
  end

  selections = [
    {
      item_id: item.id,
      workspace_id: workspace.id,
      start_time: (Time.zone.now + 30.minutes).change(sec: 0).iso8601,
      end_time:   (Time.zone.now + 45.minutes).change(sec: 0).iso8601,
      quantity: 1
    }
  ]
  add_item_to_cart(selections)
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
  add_item_to_cart(selections)
end

# --- Sees ---
Then /^(?:|I )should see my pending reservation$/ do
  page.should have_content("Your Cart")
  page.should have_content("Mic")
  page.should have_content("1")
end

# --- Actions ---