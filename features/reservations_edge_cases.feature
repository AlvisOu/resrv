Feature: Reservations Edge Cases
  As a user or owner
  I want the system to handle edge cases in reservations
  So that data integrity is maintained

  Background:
    Given a workspace named "Edge Lab" exists
    And a workspace item named "Device" with availability exists in "Edge Lab"
    And I am logged in as a workspace owner of "Edge Lab"

  Scenario: Cannot cancel a reservation that has already started
    Given I have an active reservation in "Edge Lab" for "Device"
    When I try to cancel the active reservation for "Device"
    Then I should see "You cannot cancel a reservation that has already started."

  Scenario: Non-owner cannot mark no-show
    Given I am logged in as a standard user of "Edge Lab"
    And I have a reservation in "Edge Lab" for "Device"
    When I mark the reservation as a no-show
    Then I should see "Not authorized."

  Scenario: Revert no-show status
    Given I have a reservation in "Edge Lab" for "Device"
    When I mark the reservation as a no-show
    Then I should see "marked as no-show."
    When I mark the reservation as a no-show
    Then I should see "No-show status reverted"

  Scenario: Cannot return negative quantity
    Given I have a reservation in "Edge Lab" for "Device" with 5 reserved items
    When I return -1 items from the reservation
    Then I should see "Please enter a valid number (0 or more)."

  Scenario: Cannot return more than reserved
    Given I have a reservation in "Edge Lab" for "Device" with 5 reserved items
    When I return 6 items from the reservation
    Then I should see "Cannot return more than reserved."

  Scenario: Return 0 items creates a missing report
    Given I have a reservation in "Edge Lab" for "Device" with 5 reserved items
    When I return 0 items from the reservation
    Then I should see "Marked as nothing returned. Missing report created."

  Scenario: Cannot undo return with negative quantity
    Given I have a reservation in "Edge Lab" for "Device" with 5 reserved items
    And I return 3 items from the reservation
    When I undo return of -1 items from the reservation
    Then I should see "Please enter a positive number."

  Scenario: Cannot undo return more than returned
    Given I have a reservation in "Edge Lab" for "Device" with 5 reserved items
    And I return 3 items from the reservation
    When I undo return of 4 items from the reservation
    Then I should see "Cannot undo more than returned."

  Scenario: Undo return restores missing items
    Given a workspace item named "Device2" with availability exists in "Edge Lab"
    And I have a reservation in "Edge Lab" for "Device2" with 5 reserved items
    And I return 0 items from the reservation
    Then I should see "Marked as nothing returned."
    And a missing report should exist for the reservation
    When I return 2 items from the reservation
    Then I should see "2 Device2(s) returned successfully."
    When I undo return of 1 items from the reservation
    Then I should see "Undo return of 1 Device2(s) successful."
