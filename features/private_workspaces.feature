Feature: Private Workspaces and Join Codes
  As a workspace owner
  I want to create private workspaces and share join codes
  So that I can control who joins my workspace

  Background:
    Given I am logged in as a new user named "Owner"

  Scenario: Create a private workspace with a join code
    When I go to the new workspace page
    And I fill in "workspace[name]" with "Secret Club"
    And I fill in "workspace[description]" with "Members only"
    And I uncheck "workspace[is_public]"
    And I fill in "workspace[join_code]" with "SECRET123"
    And I press "Create Workspace"
    Then I should see "Workspace was successfully created"
    And I should see "Secret Club"

  Scenario: Private workspace is hidden from search for non-members
    Given a private workspace named "Hidden Lab" exists with join code "HIDDEN"
    And I am logged in as a new user named "Stranger"
    When I go to the home page
    And I fill in "query" with "Hidden"
    And I press "Search"
    Then I should not see "Hidden Lab"

  Scenario: Join a private workspace using a valid code
    Given a private workspace named "Hidden Lab" exists with join code "HIDDEN"
    And I am logged in as a new user named "Joiner"
    When I go to the home page
    And I click "Have a join code?"
    And I fill in "join_code" with "HIDDEN"
    And I press "Join"
    Then I should see "Successfully joined Hidden Lab!"
    And I should see "Hidden Lab"

  Scenario: Fail to join with an invalid code
    Given a private workspace named "Hidden Lab" exists with join code "HIDDEN"
    And I am logged in as a new user named "Hacker"
    When I go to the home page
    And I click "Have a join code?"
    And I fill in "join_code" with "WRONG"
    And I press "Join"
    Then I should see "Invalid join code"
    And I should not see "Hidden Lab"

  Scenario: Private workspace is visible in search for members
    Given a private workspace named "Hidden Lab" exists with join code "HIDDEN"
    And I am logged in as a new user named "Member"
    And I have joined the workspace "Hidden Lab"
    When I go to the home page
    And I fill in "query" with "Hidden"
    And I press "Search"
    Then I should see "Hidden Lab"
