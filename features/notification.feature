Feature: Notification
  As a user, I want to manage my notifications
  so I can stay up-to-date and clear out old alerts.

  Background:
    Given I am logged in as a standard user of "Dodge"
    And I have 2 unread notifications: "Reservation Confirmed" and "Item Returned"

  Scenario: Viewing notifications
    When I go to my notifications page
    Then I should see "Notifications"
    And I should see "Reservation Confirmed"
    And I should see "Item Returned"
    And I should see an unread count of "2"

  Scenario: Mark a single notification as read
    When I go to my notifications page
    And I click "Mark as Read" for "Reservation Confirmed"
    Then I should see "Notification marked as read."
    And the "Reservation Confirmed" notification should be marked as read
    And I should see an unread count of "1"

  Scenario: Mark all notifications as read
    When I go to my notifications page
    And I click "Mark All as Read"
    Then I should see "All notifications marked as read."
    And I should see an unread count of "0"
    And all notifications should be marked as read

  @javascript
  Scenario: Delete all notifications
    When I go to my notifications page
    And I press "Delete All" and accept the alert
    Then I should see "All notifications deleted."
    And I should see "You have no notifications."