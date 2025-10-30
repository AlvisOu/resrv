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