Feature: User Registration
  As a new visitor
  I want to sign up for an account
  So I can access the platform

  Background:
    Given I am on the sign up page

  Scenario: Successful sign up
    When I fill in "user[name]" with "New User"
    And I fill in "user[email]" with "new@example.com"
    And I fill in "user[password]" with "password123"
    And I fill in "user[password_confirmation]" with "password123"
    And I press "Create Account"
    Then I should see "Welcome! You have signed up successfully."
    And I should be on the home page
    And I should see "Log Out"

  Scenario: Password mismatch
    When I fill in "user[name]" with "Another User"
    And I fill in "user[email]" with "another@example.com"
    And I fill in "user[password]" with "password123"
    And I fill in "user[password_confirmation]" with "wrongpassword"
    And I press "Create Account"
    Then I should see "Password confirmation doesn't match Password"
    And I should see "Sign Up"

  Scenario: Invalid or blank email
    When I fill in "user[name]" with "Test User"
    And I fill in "user[email]" with ""
    And I fill in "user[password]" with "password123"
    And I fill in "user[password_confirmation]" with "password123"
    And I press "Create Account"
    Then I should see "Email can't be blank"