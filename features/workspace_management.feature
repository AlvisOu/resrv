Feature: Workspace management
  As a user of the platform
  I want to search, create, and manage workspaces
  So I can collaborate and administer them effectively

  Background:
    Given a workspace named "Lerner" exists
    And a workspace named "Carleton Lab" exists
    And a workspace named "Uris Hall" exists
    And a workspace named "Hamilton Hall" exists

  Scenario: Search for an existing workspace by name
    And I am logged in as a standard user of "Hamilton Hall"
    When I go to "/workspaces?query=Hamilton"
    Then I should see "Hamilton Hall"

  Scenario: Fail to create a workspace with missing name
    And I am logged in as a workspace owner of "Lerner"
    When I go to the new workspace page
    And I fill in "workspace[name]" with ""
    And I press "Create Workspace"
    Then I should see "prohibited this workspace from being saved"

  Scenario: Owner fails to update workspace with invalid name
    And I am logged in as a workspace owner of "Carleton Lab"
    When I go to the edit page for workspace "Carleton Lab"
    And I fill in "workspace[name]" with ""
    And I press "Save Changes"
    Then I should see "prohibited this workspace from being saved"

  Scenario: Owner creates an item with invalid times
    Given I am logged in as a workspace owner of "Lab"
    When I open the workspace "Lab"
    And I click "Add Item"
    And I fill in "e.g., Camera Kit" with "Broken Item"
    And I fill in "10" with "5"
    And I select "14" as the start hour
    And I select "13" as the end hour
    And I press "Confirm"
    Then I should see "End time must be after the start time"
