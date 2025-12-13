Feature: Penalties Management
  As a user or workspace owner
  I want to manage penalties
  So that I can appeal unfair penalties or manage user access

  Background:
    Given a workspace exists with name "Lab"
    And a user exists with email "owner@example.com"
    And "owner@example.com" is a workspace owner of "Lab"
    And a user exists with email "member@example.com"
    And "member@example.com" is a standard user of "Lab"

  Scenario: User appeals a penalty successfully
    Given I am logged in as a standard user of "Lab"
    And I have an active penalty in "Lab"
    When I visit the profile page
    And I fill in "appeal_message" with "I was sick"
    And I press "Appeal"
    Then I should see "Appeal sent to the workspace owner."
    And the penalty should be pending appeal
    And the workspace owner should receive a notification about the appeal

  Scenario: User cannot appeal an already appealed penalty
    Given I am logged in as a standard user of "Lab"
    And I have a pending appeal penalty in "Lab"
    When I send a POST request to appeal the penalty
    Then I should see "You already submitted an appeal for this penalty."

  Scenario: User cannot appeal a resolved penalty
    Given I am logged in as a standard user of "Lab"
    And I have a resolved penalty in "Lab"
    When I send a POST request to appeal the penalty
    Then I should see "This penalty appeal was already reviewed."

  Scenario: User cannot appeal someone else's penalty
    Given I am logged in as a standard user of "Lab"
    And "owner@example.com" has an active penalty in "Lab"
    When I send a POST request to appeal the penalty for "owner@example.com"
    Then I should see "Not authorized to appeal this penalty."

  Scenario: Owner forgives a penalty
    Given I am logged in as a workspace owner of "Lab"
    And "member@example.com" has a pending appeal penalty in "Lab"
    When I visit the notifications page
    And I press "Remove Penalty"
    Then I should see "Penalty removed."
    And "member@example.com" should have no penalties in "Lab"
    And the user should receive a notification about the penalty removal

  Scenario: Owner shortens a penalty
    Given I am logged in as a workspace owner of "Lab"
    And "member@example.com" has a pending appeal penalty in "Lab"
    When I visit the notifications page
    And I fill in "shorten_hours" with "24"
    And I press "Shorten"
    Then I should see "Penalty end time reduced."
    And the user should receive a notification about the penalty reduction

  Scenario: Owner cannot shorten a penalty with invalid hours
    Given I am logged in as a workspace owner of "Lab"
    And "member@example.com" has a pending appeal penalty in "Lab"
    When I visit the notifications page
    And I fill in "shorten_hours" with "-5"
    And I press "Shorten"
    Then I should see "Enter a positive number of hours to reduce."

  Scenario: Owner cannot shorten a resolved penalty
    Given I am logged in as a workspace owner of "Lab"
    And "member@example.com" has a resolved penalty in "Lab"
    When I send a PATCH request to shorten the penalty for "member@example.com"
    Then I should see "This appeal has already been handled."

  Scenario: Non-owner cannot forgive a penalty
    Given I am logged in as a standard user of "Lab"
    And "member@example.com" has an active penalty in "Lab"
    When I send a PATCH request to forgive the penalty for "member@example.com"
    Then I should see "Only workspace owners can update penalties."

  Scenario: Non-owner cannot shorten a penalty
    Given I am logged in as a standard user of "Lab"
    And "member@example.com" has an active penalty in "Lab"
    When I send a PATCH request to shorten the penalty for "member@example.com"
    Then I should see "Only workspace owners can update penalties."
