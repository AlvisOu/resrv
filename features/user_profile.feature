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