require 'rails_helper'

RSpec.describe Reservation, type: :model do
  # --- Setup ---
  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "pw") }
  let!(:workspace) { Workspace.create!(name: "Test Workspace") }

  let(:today_9am)  { Time.zone.now.beginning_of_day + 9.hours }
  let(:today_10am) { Time.zone.now.beginning_of_day + 10.hours }
  let(:today_11am) { Time.zone.now.beginning_of_day + 11.hours }
  let(:today_4pm)  { Time.zone.now.beginning_of_day + 16.hours } # 16:00
  let(:today_5pm)  { Time.zone.now.beginning_of_day + 17.hours } # 17:00
  let(:today_6pm)  { Time.zone.now.beginning_of_day + 18.hours } # 18:00
  let(:today_8am)  { Time.zone.now.beginning_of_day + 8.hours }

  let!(:item_9_to_5) {
    Item.create!(
      name: "Conference Room",
      quantity: 1,
      workspace: workspace,
      start_time: today_9am,  # Item's window opens at 9:00
      end_time: today_5pm     # Item's window closes at 17:00
    )
  }

  # --- Associations ---
  describe "associations" do
    it "belongs to a user" do
      reservation = Reservation.new(user: user)
      expect(reservation.user).to eq(user)
    end

    it "belongs to an item" do
      reservation = Reservation.new(item: item_9_to_5)
      expect(reservation.item).to eq(item_9_to_5)
    end
  end

  # --- Standard Validations ---
  describe "standard validations" do
    it "is valid with a user, item, start_time, and end_time (within window)" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_10am, # 10:00
        end_time: today_11am    # 11:00
      )
      expect(reservation).to be_valid
    end

    it "is invalid without a start_time" do
      reservation = Reservation.new(user: user, item: item_9_to_5, end_time: today_11am)
      expect(reservation).not_to be_valid
      expect(reservation.errors[:start_time]).to include("can't be blank")
    end

    it "is invalid without an end_time" do
      reservation = Reservation.new(user: user, item: item_9_to_5, start_time: today_10am)
      expect(reservation).not_to be_valid
      expect(reservation.errors[:end_time]).to include("can't be blank")
    end
  end

  # --- Custom Validation: end_time_after_start_time ---
  describe "custom validation: end_time_after_start_time" do
    it "is invalid if end_time is *before* start_time" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_11am, # 11:00
        end_time: today_10am    # 10:00 (before start)
      )
      expect(reservation).not_to be_valid
      expect(reservation.errors[:end_time]).to include("must be after the start time")
    end

    it "is invalid if end_time is *equal to* start_time" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_10am, # 10:00
        end_time: today_10am    # 10:00 (equal)
      )
      expect(reservation).not_to be_valid
      expect(reservation.errors[:end_time]).to include("must be after the start time")
    end

    it "is valid if end_time is after start_time" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_10am,
        end_time: today_10am + 1.minute # just 1 minute after
      )
      expect(reservation).to be_valid
    end
  end

  # --- Custom Validation: check_availability (Time-of-Day Window) ---
  describe "custom validation: check_availability (9am-5pm window)" do

    it "is valid for a reservation from 10am to 11am (fully inside window)" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_10am, # 10:00
        end_time: today_11am    # 11:00
      )
      expect(reservation).to be_valid
    end

    it "is valid for a reservation from 9am to 5pm (matches window boundaries)" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_9am,  # 9:00 (matches item start)
        end_time: today_5pm     # 17:00 (matches item end)
      )
      expect(reservation).to be_valid
    end

    it "is valid for a reservation tomorrow from 10am to 11am" do
      # This confirms it's only checking time-of-day, not the date
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_10am + 1.day, # Tomorrow 10:00
        end_time: today_11am + 1.day    # Tomorrow 11:00
      )
      expect(reservation).to be_valid
    end

    it "is invalid for a reservation from 8am to 10am (starts too early)" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_8am,  # 8:00 (Item window starts at 9:00)
        end_time: today_10am    # 10:00
      )
      expect(reservation).not_to be_valid
      expect(reservation.errors[:start_time]).to include("is before the item's daily availability window")
    end

    it "is invalid for a reservation from 4pm to 6pm (ends too late)" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_4pm,  # 16:00
        end_time: today_6pm     # 18:00 (Item window ends at 17:00)
      )
      expect(reservation).not_to be_valid
      expect(reservation.errors[:end_time]).to include("is after the item's daily availability window")
    end

    it "is invalid for a reservation from 8am to 6pm (starts early AND ends late)" do
      reservation = Reservation.new(
        user: user,
        item: item_9_to_5,
        start_time: today_8am,  # 8:00 (too early)
        end_time: today_6pm     # 18:00 (too late)
      )
      expect(reservation).not_to be_valid
      # It should have both errors
      expect(reservation.errors[:start_time]).to include("is before the item's daily availability window")
      expect(reservation.errors[:end_time]).to include("is after the item's daily availability window")
    end
  end

  # --- Scope: active_for_capacity ---
  describe "scope: active_for_capacity" do
    it "includes confirmed reservations" do
      confirmed = Reservation.create!(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am, in_cart: false
      )
      expect(Reservation.active_for_capacity).to include(confirmed)
    end

    it "includes unexpired in-cart holds" do
      hold = Reservation.create!(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am,
        in_cart: true, hold_expires_at: 10.minutes.from_now
      )
      expect(Reservation.active_for_capacity).to include(hold)
    end

    it "excludes expired in-cart holds" do
      expired = Reservation.create!(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am,
        in_cart: true, hold_expires_at: 10.minutes.ago
      )
      expect(Reservation.active_for_capacity).not_to include(expired)
    end
  end

  # --- Class Method: notify_and_purge_expired_holds! ---
  describe ".notify_and_purge_expired_holds!" do
    it "removes expired holds and creates notifications" do
      expired = Reservation.create!(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am,
        in_cart: true, hold_expires_at: 5.minutes.ago
      )
      
      expect {
        Reservation.notify_and_purge_expired_holds!
      }.to change(Reservation, :count).by(-1)
       .and change(Notification, :count).by(1)

      expect(Reservation.exists?(expired.id)).to be false
      expect(Notification.last.user).to eq(user)
      expect(Notification.last.message).to include("expired and was removed")
    end

    it "does not remove active holds" do
      Reservation.create!(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am,
        in_cart: true, hold_expires_at: 5.minutes.from_now
      )

      expect {
        Reservation.notify_and_purge_expired_holds!
      }.not_to change(Reservation, :count)
    end

    it "uses a fallback message when item/workspace data is missing" do
      expired = Reservation.create!(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am,
        in_cart: true, hold_expires_at: 5.minutes.ago
      )

      allow_any_instance_of(Reservation).to receive(:item).and_return(nil)

      Reservation.notify_and_purge_expired_holds!

      expect(Notification.last.message).to include("One of your held reservations expired")
      expect(Reservation.exists?(expired.id)).to be false
    end
  end

  # --- Capacity Validation ---
  describe "capacity validation" do
    it "prevents booking if item is fully booked" do
      # Item quantity is 1. Create one reservation.
      Reservation.create!(user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am)

      overlapping = Reservation.new(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am
      )

      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:base].join).to include("fully booked")
    end

    it "allows booking if capacity remains" do
      item_9_to_5.update!(quantity: 2)
      
      Reservation.create!(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am
      )

      overlapping = Reservation.new(
        user: user, item: item_9_to_5, start_time: today_10am, end_time: today_11am
      )
      
      expect(overlapping).to be_valid
    end
  end

  # --- Auto Mark Missing Items ---
  describe "#auto_mark_missing_items" do
    # Create an item that is open 24/7 to avoid window validation issues during tests
    let!(:item_24h) {
      Item.create!(
        name: "24h Item",
        quantity: 1,
        workspace: workspace,
        start_time: Time.zone.now.beginning_of_day,
        end_time: Time.zone.now.end_of_day
      )
    }

    let(:past_reservation) {
      Reservation.create!(
        user: user, item: item_24h,
        start_time: 2.hours.ago, end_time: 1.hour.ago,
        quantity: 1, returned_count: 0
      )
    }

    it "does nothing if reservation is not yet overdue (within 30 min grace period)" do
      just_finished = Reservation.create!(
        user: user, item: item_24h,
        start_time: 2.hours.ago, end_time: 5.minutes.ago,
        quantity: 1, returned_count: 0
      )
      
      expect {
        just_finished.auto_mark_missing_items
      }.not_to change(MissingReport, :count)
    end

    it "creates a missing report and decrements item quantity if overdue and not returned" do
      # End time was 1 hour ago, so it's > 30 mins overdue
      expect {
        past_reservation.auto_mark_missing_items
      }.to change(MissingReport, :count).by(1)
       .and change { item_24h.reload.quantity }.by(-1)
      
      report = MissingReport.last
      expect(report.reservation).to eq(past_reservation)
      expect(report.quantity).to eq(1)
    end

    it "does nothing if items were returned" do
      past_reservation.update!(returned_count: 1)
      expect {
        past_reservation.auto_mark_missing_items
      }.not_to change(MissingReport, :count)
    end

    it "does not create duplicate reports" do
      past_reservation.auto_mark_missing_items
      expect {
        past_reservation.auto_mark_missing_items
      }.not_to change(MissingReport, :count)
    end
  end
end
