# --- Givens ---
Given /^a workspace named "([^"]*)" exists$/ do |workspace_name|
  Workspace.find_or_create_by!(name: workspace_name)
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

# --- Actions ---
When /^(?:|I )fill in the workspace information$/ do
  @workspace_name = "My New Test Workspace"
  fill_in("workspace[name]", with: @workspace_name)
end
Then /^(?:|I )the new workspace should appear in my list of workspaces$/ do
  page.should have_content(@workspace_name)
end

Given('a workspace item named {string} exists in {string}') do |item_name, ws_name|
  ws = Workspace.find_or_create_by!(name: ws_name)
  Item.find_or_create_by!(name: item_name, workspace: ws) do |it|
    it.quantity   = 10
    it.start_time = Time.zone.today.beginning_of_day
    it.end_time   = Time.zone.today.end_of_day
  end
end

When /^I open the workspace "([^"]*)"$/ do |workspace_name|
  card = find('.card', text: workspace_name)
  
  if card.has_link?('View Workspace')
    card.click_link('View Workspace')
  elsif card.has_link?('Manage Workspace')
    card.click_link('Manage Workspace')
  else
    raise "Could not find 'View Workspace' or 'Manage Workspace' link for #{workspace_name}"
  end
end

Given /^a private workspace named "([^"]*)" exists with join code "([^"]*)"$/ do |name, code|
  Workspace.create!(
    name: name,
    is_public: false,
    join_code: code
  )
end

Given /^I have joined the workspace "([^"]*)"$/ do |workspace_name|
  workspace = Workspace.find_by!(name: workspace_name)
  UserToWorkspace.create!(
    user: @current_user,
    workspace: workspace,
    role: 'user' # Default to standard user
  )
end

When("I send a POST request to join the workspace {string}") do |workspace_name|
  workspace = Workspace.find_by!(name: workspace_name)
  page.driver.submit :post, workspace_user_to_workspace_path(workspace), {}
end

When("I visit the workspace {string} page with date {string}") do |workspace_name, date|
  workspace = Workspace.find_by!(name: workspace_name)
  visit workspace_path(workspace, day: date)
end

Then("the page should show availability for {string}") do |date|
  parsed_date = Date.parse(date)
  formatted_date = parsed_date.strftime("%B %-d") # e.g. December 15
  expect(page).to have_content(formatted_date)
end
