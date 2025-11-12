Feature: Reservation Reminders
  As a user
  I want to receive notifications for my reservations
  So I don't forget when they start or end

  Background:
    Given a complete reservation exists

  Scenario: Receive a start reminder
    When the "start" reminder job runs for my reservation
    Then I should have 1 notification
    And the notification message should contain "starts in 2 hours!"

  Scenario: Receive an end reminder
    When the "end" reminder job runs for my reservation
    Then I should have 1 notification
    And the notification message should contain "ends in 10 minutes!"

  Scenario: Job handles a missing reservation
    When the reminder job runs for a non-existent reservation
    Then I should have 0 notifications