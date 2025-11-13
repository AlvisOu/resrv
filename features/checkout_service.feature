Feature: CheckoutService edge cases

  Background:
    Given a workspace named "Lab" exists
    And a workspace item named "Mic" exists in "Lab"
    And a user named "Alice User" exists

  Scenario: No items in cart for this workspace
    Given an empty checkout cart for workspace 999
    When I run checkout for "Alice User" and workspace 999
    Then the checkout should fail with "No items in cart for this workspace."

  Scenario: Transaction rolls back when a segment is invalid
    # end_time <= start_time triggers process_segment -> false -> raises rollback
    Given a checkout cart for "Lab" with a segment for "Mic" from "1:00 PM" to "1:00 PM" qty 1
    When I run checkout for "Alice User" and workspace "Lab"
    Then the checkout should fail with "Invalid time/quantity for Mic."
    And no new reservations should exist for "Alice User"

  Scenario: Blocked user cannot reserve
    Given a checkout cart for "Lab" with a segment for "Mic" from "1:00 PM" to "1:15 PM" qty 1
    And the user "Alice User" is blocked in "Lab"
    When I run checkout for "Alice User" and workspace "Lab"
    Then the checkout should fail with "You are blocked from making reservations in Lab due to a recent penalty."

  Scenario: Capacity failure (excluding own holds)
    Given "Mic" has quantity 1
    And another user has a reservation for "Mic" from "1:00 PM" to "1:15 PM" qty 1
    And a checkout cart for "Lab" with a segment for "Mic" from "1:00 PM" to "1:15 PM" qty 1
    When I run checkout for "Alice User" and workspace "Lab"
    Then the checkout should fail with "Not enough capacity for Mic between 1:00 PM–1:15 PM."

  Scenario: Holds exist but don’t fully cover segment (triggers coverage < seg_qty path)
    Given "Mic" has quantity 1
    And the user "Alice User" has an in-cart hold for "Mic" from "1:00 PM" to "1:15 PM" qty 1
    And a checkout cart for "Lab" with a segment for "Mic" from "1:00 PM" to "1:15 PM" qty 2
    When I run checkout for "Alice User" and workspace "Lab"
    Then the checkout should fail with "Not enough capacity for Mic between 1:00 PM–1:15 PM."

  Scenario: Direct capacity_available? helper (private) is callable
    Given "Mic" has quantity 2
    And another user has a reservation for "Mic" from "1:00 PM" to "1:15 PM" qty 1
    When I call the private capacity helper for "Mic" from "1:00 PM" to "1:15 PM" qty 1
    Then it should report capacity available
    When I call the private capacity helper for "Mic" from "1:00 PM" to "1:15 PM" qty 2
    Then it should report capacity unavailable
