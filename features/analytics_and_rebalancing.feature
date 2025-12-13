Feature: Analytics dashboards and capacity rebalancing
  To keep analytics and capacity logic reliable
  Workspace owners should be able to view analytics pages
  and inventory should be rebalanced when capacity drops.

  Background:
    Given a workspace named "Coverage Lab" exists
    And a user exists with email "member@example.com"

  Scenario: Owner views per-user analytics dashboard
    And the workspace "Coverage Lab" has recent activity for user "member@example.com"
    And I am logged in as a workspace owner of "Coverage Lab"
    When I visit the user analytics page for workspace "Coverage Lab" and user "member@example.com"
    Then I should see "Usage Metrics in This Workspace"
    And I should see "No-Show Count"
    And I should see "Past Reservations"

  Scenario: Owner reviews workspace analytics and downloads CSVs
    And the workspace "Coverage Lab" has recent activity for user "member@example.com"
    And I am logged in as a workspace owner of "Coverage Lab"
    When I visit the analytics page for workspace "Coverage Lab"
    Then I should see "Analytics – Coverage Lab"
    When I follow the first "Download CSV" link
    Then I should see "Utilization (%)"

  Scenario: Capacity rebalancing cancels excess reservations
    And the workspace "Coverage Lab" has overlapping reservations exceeding capacity
    When I trigger capacity rebalancing for workspace "Coverage Lab"
    Then one overbooked reservation should be canceled
    And a notification should be recorded for the canceled reservation

  Scenario: Owner downloads all analytics CSVs
    Given I am logged in as a workspace owner of "Lab"
    When I visit the workspace "Lab" analytics page
    And I click "Download CSV" in the "Utilization" section
    Then the response content type should be "text/csv"
    When I visit the workspace "Lab" analytics page
    And I click "Download CSV" in the "Behavior Metrics" section
    Then the response content type should be "text/csv"
    When I visit the workspace "Lab" analytics page
    And I click "Download CSV" in the "Heatmap" section
    Then the response content type should be "text/csv"
