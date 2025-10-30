Feature: Owner Workflow for Workspace Management

  Background:
    Given I am logged in as a workspace owner of "Lerner Auditorium"
    And a workspace item named "Mic" with availability exists in "Lerner Auditorium"

Scenario: Create a new workspace
  When I go to my owned/bookmarked workspaces
  And  I click "Create New Workspace"
  Then I should see "Create a New Workspace"
  When I fill in the workspace information
  And  I click "Create Workspace"
  Then the new workspace should appear in my list of workspaces

Scenario: Create a new item in a workspace
  When I go to my "Lerner Auditorium" workspace
  And  I click "Add Item"
  And  I fill in the name "Projector", start time, end time, and quantity
  And  I click "Confirm"
  Then I should see "Projector"

Scenario: Modify an existing item in a workspace
  When I go to my "Lerner Auditorium" workspace
  Then I should see "Mic"
  When I click "Mic"
  And  I change the name, start time, end time, and quantity
  And  I click "Confirm"
  Then the "Mic" item details should be updated

Scenario: Delete an item from a workspace
  When I go to my "Lerner Auditorium" workspace
  Then I should see "Mic"
  When I click "Mic"
  And  I click "Delete"
  Then I should not see "Mic"