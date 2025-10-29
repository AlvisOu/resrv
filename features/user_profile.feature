Feature: User profile management

  Background:
    Given a workspace named "Lerner Auditorium" exists
    And a user exists with email "bob@example.com"
    And "bob@example.com" is a standard user of "Lerner Auditorium"
    And I am logged in as a standard user of "Lerner Auditorium"

  Scenario: Fail to update profile with empty name
    When I go to the profile page
    And I fill in "user[name]" with ""
    And I fill in "user[password]" with "newpass123"
    And I fill in "user[password_confirmation]" with "newpass123"
    And I press "Update Profile"
    Then I should see "There was a problem updating your profile."

  Scenario: Successfully update profile
    When I go to the profile page
    And I fill in "user[name]" with "Bobby"
    And I fill in "user[password]" with "newpass123"
    And I fill in "user[password_confirmation]" with "newpass123"
    And I press "Update Profile"
    Then I should see "Profile updated successfully."

  @javascript
  Scenario: Cannot delete account while owning workspaces
    Given a workspace named "Lerner Auditorium" exists
    And I am logged in as a workspace owner of "Lerner Auditorium"
    When I go to the profile page
    And I press "Delete My Account" and accept the alert
    Then I should see "You must delete or transfer ownership of all your workspaces before deleting your account."

  Scenario: Successfully delete account as standard user
    Given a workspace named "Lerner Auditorium" exists
    And a user exists with email "alice@example.com"
    And "alice@example.com" is a standard user of "Lerner Auditorium"
    And I am logged in as a standard user of "Lerner Auditorium"
    When I go to the profile page
    And I press "Delete My Account"
    Then I should see "Your account has been deleted."
    And I should be on the signup page