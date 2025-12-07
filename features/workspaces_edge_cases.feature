Feature: Workspaces Edge Cases
  As a user or owner
  I want the system to handle edge cases in workspaces
  So that the application remains stable

  Background:
    Given a workspace named "Edge Workspace" exists
    And a user exists with email "owner@example.com"
    And "owner@example.com" is a workspace owner of "Edge Workspace"
    And I am logged in as a workspace owner of "Edge Workspace"

  Scenario: Join by code with blank code
    When I go to the home page
    And I click "Have a join code?"
    And I fill in "join_code" with ""
    And I press "Join"
    Then I should see "Please enter a join code."

  Scenario: Join by code when already a member
    Given a private workspace named "Secret Lab" exists with join code "SECRET"
    And I have joined the workspace "Secret Lab"
    When I go to the home page
    And I click "Have a join code?"
    And I fill in "join_code" with "SECRET"
    And I press "Join"
    Then I should see "You are already a member of this workspace."

  Scenario: Owner views past reservations
    When I go to the "Edge Workspace" workspace page
    And I click "View past reservations"
    Then I should see "Past Reservations"

  Scenario: Owner changes analytics date range
    When I visit the analytics page for workspace "Edge Workspace"
    And I follow "1 Month"
    Then I should see "Analytics – Edge Workspace"

  Scenario: Owner changes analytics user ranking
    When I visit the analytics page for workspace "Edge Workspace"
    And I follow "By Recency"
    Then I should see "Analytics – Edge Workspace"

  Scenario: Owner downloads utilization CSV
    When I visit the analytics page for workspace "Edge Workspace"
    And I click the "Download CSV" link for "Utilization"
    Then the response should contain "Item,Reserved Blocks,Total Blocks,Utilization (%)"

  Scenario: Owner downloads behavior CSV
    When I visit the analytics page for workspace "Edge Workspace"
    And I click the "Download CSV" link for "Behavior Metrics"
    Then the response should contain "Item,Total Reservations,Missing Rate,Late Return Rate"

  Scenario: Owner downloads heatmap CSV
    When I visit the analytics page for workspace "Edge Workspace"
    And I click the "Download CSV" link for "Heatmap"
    Then the response should contain "Item,12:00 AM"

