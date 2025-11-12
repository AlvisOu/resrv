Feature: Missing Reports Management
  As a workspace owner
  I want to manage missing item reports
  So I can track and resolve inventory discrepancies

  Background:
    Given I am logged in as a workspace owner of "TechLab"
    And I have an existing reservation
    And "owner@example.com" is a workspace owner of "TechLab"
    And a workspace item named "Wireless Microphone" with availability exists in "TechLab"

  Scenario: View missing reports
    Given there is an existing missing report for my reservation
    And there is also an existing resolved report
    When I go to the missing reports page for "TechLab"
    Then I should see "Missing Items for TechLab"
    And I should see "Currently Missing"
    And I should see "Resolved Reports"
    And I should see my reservation in the unresolved reports

  Scenario: Create a missing report for a reservation with missing items
    Given my reservation has 5 items where 2 were returned
    When I go to My Reservations
    And I press "Report Missing Items"
    Then I should be redirected to my reservation page
    And I should see "Missing item reported."
    And the item quantity should be decreased by 3

  Scenario: Attempt to create missing report when all items are returned
    Given my reservation has 3 items where all 3 were returned
    When I go to My Reservations
    And I press "Report Missing Items"
    Then I should see "No missing quantity to report."
    And the item quantity should remain unchanged

  Scenario: Resolve a missing report
    Given there is an existing missing report for my reservation
    When I go to the missing reports page for "TechLab"
    And I press "Mark as Resolved" for my missing report
    Then I should see "Item marked as back online."
    And I should be redirected to the missing reports page
    And the missing report should be marked as resolved
    And the item quantity should be restored

  Scenario: Unauthorized user cannot access missing reports
    Given I am logged in as a standard user of "TechLab"
    When I go to the missing reports page for "TechLab"
    Then I should be redirected to the home page
    And I should see "Not authorized."

  @javascript
  Scenario: Resolve missing report with confirmation
    Given there is an existing missing report for my reservation
    When I go to the missing reports page for "TechLab"
    And I press "Mark as Resolved" and accept the alert for my missing report
    Then I should see "Item marked as back online."
    And the missing report should be marked as resolved