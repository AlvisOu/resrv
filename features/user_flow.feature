Feature: User Workflow for Workspace Reservations

Background:
  Given I am logged in as a standard user of "Lerner Auditorium"
  And a workspace item named "Mic" with availability exists in "Lerner Auditorium"

Scenario: Make a microphone reservation
  When I go to my owned/bookmarked workspaces
  And  I click "Lerner Auditorium"
  Then I should see "Mic" and its availabilities
  When I adjust the quantity for "Mic"
  And  I press an available time slot
  And  I press the shopping cart icon
  When I go to cart
  Then I should see my pending reservation
  When I click "resrv"
  And  I go to My Reservations
  Then I should see the new reservation for "Mic"

Scenario: Cancel a microphone reservation
  Given I have an existing reservation
  When I go to My Reservations
  Then I should see all my reservations
  When I click "cancel" on the reservation for "Mic"
  Then I should see a confirmation message
  Then I should not see the reservation for "Mic"