Feature: Workspace Membership
  As a user, I want to manage my workspace memberships
  So I can access the correct projects or leave ones I am done with.

    Background:
      Given a workspace named "Butler Library" exists
      And a user exists with email "new_member@example.com"

    Scenario: Standard user joins (bookmarks) a workspace
      Given I am logged in as a standard user of "My First Workspace"
      When I go to the "Butler Library" workspace page
      And I click "Bookmark"
      Then I should see "You have successfully joined"
      When I go to my owned/bookmarked workspaces
      Then I should see "Butler Library"

    Scenario: Standard user leaves a workspace
      Given I am logged in as a standard user of "Butler Library"
      When I go to my owned/bookmarked workspaces
      And I open the workspace "Butler Library"
      And I click "Unbookmark"
      Then I should see "You have left Butler Library"

    Scenario: Owner leaves (and deletes) their workspace
      Given I am logged in as a workspace owner of "Lerner Auditorium"
      When I go to the "Lerner Auditorium" workspace page
      And I click "Edit Workspace"
      And I click "Delete Workspace"
      Then I should see "Workspace 'Lerner Auditorium' was permanently deleted."
      And I should be on the home page
      When I go to my owned/bookmarked workspaces
      Then I should not see "Lerner Auditorium"