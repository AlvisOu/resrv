Feature: User Workflow for Workspace Reservations

Background:
    Given I am logged in as a standard user

Scenario: Make a microphone reservation
  When I go to my owned/bookmarked Workspaces
  And  I press "Lerner Auditorium"
  Then I should see "Mic" and its availabilities
  When I adjust the quantity for "Mic"
  And  I press an available time slot
  And  I press the shopping cart icon
  Then I should see my pending reservation
  When I click "resrv"
  And  I go to "My Reservation"
  Then I should see the new reservation for "Mic"

Scenario: Cancel a microphone reservation
  Given I have an existing reservation
  When I go to "My Reservation"
  Then I should see all my reservations
  When I click "cancel" on the reservation
  Then I should see a confirmation message
  When I click "yes" to confirm
  Then I should not see the old reservation