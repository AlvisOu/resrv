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
    And the reservation has ended over 30 minutes ago
    When I trigger the automatic missing item check
    Then a missing report should be created
    And the item quantity should be decreased by 3

  @javascript
  Scenario: Resolve a missing report
    Given there is an existing missing report for my reservation
    When I go to the missing reports page for "TechLab"
    And I press "✅ Mark as Back Online" and accept the alert for my missing report
    Then I should see "Item marked as back online."
    And I should see my reservation in the resolved reports
    And the item quantity should be increased by 2

  Scenario: Unauthorized user cannot access missing reports
    Given I am logged in as a standard user of "TechLab"
    When I go to the missing reports page for "TechLab"
    Then I should be on the home page
    And I should see "Not authorized."

  Scenario: Create a missing report via the controller (success)
    Given I am logged in as a workspace owner of "TechLab"
    And I have an existing reservation
    And "owner@example.com" is a workspace owner of "TechLab"
    And a workspace item named "Wireless Microphone" with availability exists in "TechLab"
    And my reservation has 5 items where 2 were returned
    And the reservation has ended over 30 minutes ago

    When I create a missing report for my reservation via the controller
    Then a missing report should be created
    And the item quantity should be decreased by 3

  Scenario: Attempt to create a missing report when nothing is missing
    Given I am logged in as a workspace owner of "TechLab"
    And I have an existing reservation
    And "owner@example.com" is a workspace owner of "TechLab"
    And a workspace item named "Wireless Microphone" with availability exists in "TechLab"
    And my reservation has 3 items where 3 were returned
    And the reservation has ended over 30 minutes ago

    When I create a missing report for my reservation via the controller
    Then there should be no missing report for my reservation
    And the item quantity should remain unchanged

  Scenario: Unauthorized user cannot create a missing report
    Given I am logged in as a standard user of "TechLab"
    And I have an existing reservation
    And a workspace item named "Wireless Microphone" with availability exists in "TechLab"
    And my reservation has 4 items where 1 were returned
    And the reservation has ended over 30 minutes ago

    When I create a missing report for my reservation via the controller
    Then I should be on the home page
    And I should see "Not authorized."
