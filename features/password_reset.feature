Feature: Password Reset Workflow

  Background:
    Given a user exists with email "user@example.com"
    And I am on the login page

  Scenario: User requests a password reset
    When I click "Forgot password?"
    Then I should be on the new password reset page
    When I fill in "email" with "user@example.com"
    And I press "Send password reset email"
    Then I should see "we have sent a password reset link."
    And an email should be sent to "user@example.com"

  Scenario: User successfully resets password with a valid token
    Given "user@example.com" has requested a password reset
    When I visit the password reset link from the email
    Then I should see "Choose a new password"
    When I fill in "password" with "newpass123"
    And I fill in "password_confirmation" with "newpass123"
    And I press "Reset Password"
    Then I should see "Password successfully reset! You are now logged in."
    And I should be on the home page

  Scenario: User fails to reset with mismatched passwords
    Given "user@example.com" has requested a password reset
    When I visit the password reset link for "user@example.com"
    Then I should see "Choose a new password"
    When I fill in "password" with "newpass123"
    And I fill in "password_confirmation" with "wrongpass"
    And I press "Reset Password"
    Then I should see "Password confirmation doesn't match Password"

  Scenario: User fails to reset with an invalid token
    When I visit the password reset page with an invalid token "INVALID_TOKEN"
    Then I should see "Password reset link is invalid or has expired."
    And I should be on the new password reset page

  Scenario: User requests a password reset (Non-existent User)
    When I click "Forgot password?"
    Then I should be on the new password reset page
    When I fill in "email" with "nobody@example.com"
    And I press "Send password reset email"
    Then I should see "we have sent a password reset link."
    And no email should be sent

  Scenario: User requests a password reset (Unverified User)
    Given a user exists with email "unverified@example.com"
    And that user is not verified
    When I click "Forgot password?"
    Then I should be on the new password reset page
    When I fill in "email" with "unverified@example.com"
    And I press "Send password reset email"
    Then I should see "Your account is not verified. We sent a new verification code to your email."
    And I should be on the email verification page

  Scenario: User fails to reset with an expired token (on page load)
    Given "user@example.com" has requested a password reset
    And 15 minutes have passed
    When I visit the password reset link for "user@example.com"
    Then I should see "Password reset link is invalid or has expired."
    And I should be on the new password reset page

  Scenario: User fails to reset with an expired token (on form submit)
    Given "user@example.com" has requested a password reset
    When I visit the password reset link for "user@example.com"
    Then I should see "Choose a new password"
    And 15 minutes have passed
    When I fill in "password" with "newpass123"
    And I fill in "password_confirmation" with "newpass123"
    And I press "Reset Password"
    Then I should see "Password reset link is invalid or has expired."
    And I should be on the new password reset page