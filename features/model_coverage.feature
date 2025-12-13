Feature: Model Logic Coverage
  To ensure data integrity and correct business logic
  I want to verify model methods and scopes work as expected

  Scenario: User email is downcased
    Given a user is created with email "UPPERCASE@Example.com"
    Then the user's email should be "uppercase@example.com"

  Scenario: User penalty blocking logic
    Given a user exists with email "bad@example.com"
    And a workspace named "Strict Lab" exists
    And "bad@example.com" has an active penalty in "Strict Lab"
    Then "bad@example.com" should be blocked from reserving in "Strict Lab"
    When the penalty expires
    Then "bad@example.com" should not be blocked from reserving in "Strict Lab"

  Scenario: Penalty helper methods
    Given a penalty exists with reason "late_return" and appeal state "pending"
    Then the penalty should be a late return
    And the penalty should not be a no show
    And the penalty appeal should be pending
    And the penalty should be appealed

  Scenario: Penalty active scope
    Given a user exists with email "user@example.com"
    And a workspace named "Lab" exists
    And "user@example.com" has an active penalty in "Lab"
    And "user@example.com" has an expired penalty in "Lab"
    Then "user@example.com" should have 1 active penalty in "Lab"
