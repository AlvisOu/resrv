Feature: Owner Workflow for Workspace Management

  Background:
    Given I am logged in as a workspace owner of "Lerner Auditorium"

Scenario: Create a new workspace
  When I go to my owned/bookmarked workspaces
  And  I press "Create New Workspace"
  Then I should see a "Create a New Workspace"
  When I fill in the workspace information
  And  I click the "create workspace" button
  Then the new workspace should appear in my list of workspaces

Scenario: Create a new item in a workspace
  When I go to my "Lerner Auditorium" workspace
  And  I press "Add Item"
  And  I fill in the name "Mic", start time, end time, quantity, and description
  And  I click "create"
  Then I should see "Mic" in the "Lerner Auditorium" workspace

Scenario: Modify an existing item in a workspace
  When I go to my "Lerner Auditorium" workspace
  Then I should see "Mic" and its availabilities
  When I press "Mic" to edit it
  And  I change the name, start time, end time, quantity, or description
  And  I click "confirm"
  Then the "Mic" item details should be updated

Scenario: Delete an item from a workspace
  When I go to my "Lerner Auditorium" workspace
  Then I should see "Mic" and its availabilities
  When I press "Mic" to edit it
  And  I click "delete"
  And  I click "confirm"
  Then I should not see "Mic" in the "Lerner Auditorium" workspace