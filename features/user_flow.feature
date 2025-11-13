Feature: User Workflow for Workspace Reservations

Background:
  Given I am logged in as a standard user of "Lerner Auditorium"
  And a workspace item named "Mic" with availability exists in "Lerner Auditorium"

@javascript
Scenario: Make a microphone reservation
  When I go to my owned/bookmarked workspaces
  And  I click "Lerner Auditorium"
  Then I should see "Mic"
  When I adjust the quantity for "Mic"
  And I press an available time slot for "Mic"
  And  I press "Add to Cart" and accept the alert
  When I go to cart
  Then I should see my pending reservation
  When I click "resrv" within "#checkout-form"
  And  I go to My Reservations
  Then I should see the new reservation for "Mic"

Scenario: Cancel a microphone reservation
  Given I have an existing reservation
  When I go to My Reservations
  Then I should see all my reservations
  When I click "cancel" on the reservation for "Mic"
  Then I should see "Reservation canceled successfully."
  Then I should not see the reservation for "Mic"

@javascript
Scenario: Cart update quantity (success)
  Given my cart already contains 1 selection
  When I PATCH JSON to "/cart_items/0.json" with:
    """
    { "quantity": 3 }
    """
  Then the JSON response should include "ok" true
  And the JSON response should include "total" 3

@javascript
Scenario: Cart update with invalid index raises error and is rescued
  Given my cart already contains 1 selection
  When I PATCH JSON to "/cart_items/999.json" with:
    """
    { "quantity": 2 }
    """
  Then the response status should be 422
  And the JSON response should include "ok" false
  And the JSON response should include "error" "Invalid cart index"

@javascript
Scenario: Cart destroy removes one entry
  Given my cart already contains 1 selection
  When I DELETE JSON "/cart_items/0.json"
  Then the JSON response should include "ok" true
  And the JSON response should include "total" 0

@javascript
Scenario: Cart remove_range via JSON removes only the targeted slot
  Given my cart contains the following selections:
    | item_id | workspace_id | start_time           | end_time             | quantity |
    | 1       | 1            | 2025-10-31T10:00:00Z | 2025-10-31T10:15:00Z | 1        |
    | 1       | 1            | 2025-10-31T10:15:00Z | 2025-10-31T10:30:00Z | 1        |
    When I DELETE JSON "/cart_items/remove_range.json?item_id=1&workspace_id=1&start_time=2025-10-31T10:00:00Z&end_time=2025-10-31T10:15:00Z"

  Then the JSON response should include "ok" true
  And the JSON response should include "total" 1

@javascript
Scenario: Cart remove_range via HTML redirects with notice
  # Seed the same two slots, then hit the HTML branch (no .json)
  Given my cart contains the following selections:
    | item_id | workspace_id | start_time           | end_time             | quantity |
    | 1       | 1            | 2025-10-31T11:00:00Z | 2025-10-31T11:15:00Z | 1        |
    | 1       | 1            | 2025-10-31T11:15:00Z | 2025-10-31T11:30:00Z | 1        |
  When I POST to "/cart_items/remove_range" (form) with params:
    | item_id      | 1                    |
    | workspace_id | 1                    |
    | start_time   | 2025-10-31T11:00:00Z |
    | end_time     | 2025-10-31T11:15:00Z |
    | _method      | delete               |
  Then I should be on the home page
  And I should see "Removed from cart."

@javascript
Scenario: Unauthenticated users are redirected when posting to cart
  When I click "User"
  And I click "Log Out"
  And I POST to "/cart_items" (form) with params:
    | selections | [] |
  Then I should be on the login page
