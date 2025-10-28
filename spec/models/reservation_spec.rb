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
end
