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

  @javascript
  Scenario: Delete a single notification
    When I go to my notifications page
    And I press "Delete" for "Reservation Confirmed" and accept the alert
    Then I should see "Notification deleted."
    And I should not see "Reservation Confirmed"
    And I should see "Item Returned"
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

  @javascript @owner_notification
  Scenario: Owner resolves a penalty appeal from notifications
    Given I am logged in as a workspace owner of "Lerner Auditorium"
    And a pending penalty appeal notification exists for "Lerner Auditorium"
    When I go to my notifications page
    And I press "Remove Penalty" for "Appealed penalty in Lerner Auditorium" and accept the alert
    Then I should see "Penalty removed."

  @javascript @owner_notification
  Scenario: Owner shortens a penalty from notifications
    Given I am logged in as a workspace owner of "Lerner Auditorium"
    And a pending penalty appeal notification exists for "Lerner Auditorium"
    When I go to my notifications page
    And I fill in "shorten_hours" with "2"
    And I press "Shorten"
    Then I should see "Penalty end time reduced."

  @user_notification
  Scenario: User submits a penalty appeal from workspace
    Given I am logged in as a standard user of "Lerner Auditorium"
    And I have an active penalty in "Lerner Auditorium"
    When I go to my "Lerner Auditorium" workspace
    And I fill in "appeal_message" with "Please review my case"
    And I press "Appeal Penalty"
    Then I should see "Appeal sent to the workspace owner."
