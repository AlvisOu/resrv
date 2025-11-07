require 'rails_helper'

RSpec.describe Item, type: :model do
  let!(:workspace) { Workspace.create!(name: "Test Workspace") }

  let(:base_attributes) do
    {
      name: "Conference Room A",
      quantity: 1,
      start_time: Time.zone.now.beginning_of_day + 9.hours, # 9:00 AM
      end_time: Time.zone.now.beginning_of_day + 17.hours, # 5:00 PM
      workspace: workspace
    }
  end

  # Validations
  describe "validations" do
    context "with valid attributes" do
      it "is valid" do
        item = Item.new(base_attributes)
        expect(item).to be_valid
      end
    end

    context "with invalid attributes" do
      it "is invalid without a name" do
        item = Item.new(base_attributes.merge(name: nil))
        expect(item).not_to be_valid
        expect(item.errors[:name]).to include("can't be blank")
      end

      it "is invalid without a quantity" do
        item = Item.new(base_attributes.merge(quantity: nil))
        expect(item).not_to be_valid
        expect(item.errors[:quantity]).to include("can't be blank")
      end

      it "is invalid with a non-integer quantity" do
        item = Item.new(base_attributes.merge(quantity: 1.5))
        expect(item).not_to be_valid
        expect(item.errors[:quantity]).to include("must be an integer")
      end

      it "is invalid with a negative quantity" do
        item = Item.new(base_attributes.merge(quantity: -1))
        expect(item).not_to be_valid
        expect(item.errors[:quantity]).to include("must be greater than or equal to 0")
      end

      it "is valid with a quantity of 0" do
        item = Item.new(base_attributes.merge(quantity: 0))
        expect(item).to be_valid
      end
    end
  end

  describe "custom validation: end_time_after_start_time" do
    let(:start_time) { Time.zone.now + 1.hour }

    it "is invalid if end_time is *before* start_time" do
      item = Item.new(base_attributes.merge(
        start_time: start_time,
        end_time: start_time - 1.minute # before
      ))
      expect(item).not_to be_valid
      expect(item.errors[:end_time]).to include("must be after the start time")
    end

    it "is invalid if end_time is *equal to* start_time" do
      item = Item.new(base_attributes.merge(
        start_time: start_time,
        end_time: start_time # equal
      ))
      expect(item).not_to be_valid
      expect(item.errors[:end_time]).to include("must be after the start time")
    end

    it "is valid if end_time is after start_time" do
      item = Item.new(base_attributes.merge(
        start_time: start_time,
        end_time: start_time + 1.minute # after
      ))
      expect(item).to be_valid
    end

    it "does not run if start_time is missing" do
      item = Item.new(base_attributes.merge(start_time: nil))
      expect(item).not_to be_valid
      expect(item.errors[:start_time]).to include("can't be blank")
      expect(item.errors[:end_time]).not_to include("must be after the start time")
    end

    it "does not run if end_time is missing" do
      item = Item.new(base_attributes.merge(end_time: nil))
      expect(item).not_to be_valid
      expect(item.errors[:end_time]).to include("can't be blank")
      expect(item.errors[:end_time]).not_to include("must be after the start time")
    end
  end

  # --- Associations ---
  describe "associations" do
    let!(:item) { Item.create!(base_attributes) }
    let!(:user) { 
      User.create!(
        name: "Test User", 
        email: "test@example.com", 
        password: "password123"
      ) 
    }
    let!(:reservation) { 
      Reservation.create!(
        user: user, 
        item: item,
        start_time: item.start_time + 1.hour, # 10:00 AM
        end_time: item.start_time + 2.hours  # 11:00 AM
      ) 
    }

    it "belongs to a workspace" do
      expect(item.workspace).to eq(workspace)
    end

    it "has many reservations" do
      expect(item.reservations).to include(reservation)
    end

    it "has many users (through reservations)" do
      item.reload
      expect(item.users).to include(user)
    end
  end

  # --- Dependent Behavior ---
  describe "dependent: :destroy" do
    it "destroys associated reservations when the item is destroyed" do
      item = Item.create!(base_attributes)
      user = User.create!(name: "Temp User", email: "temp@example.com", password: "pw")
      Reservation.create!(
        user: user, 
        item: item,
        start_time: item.start_time + 1.hour,
        end_time: item.start_time + 2.hours
      )

      expect { item.destroy }.to change(Reservation, :count).by(-1)
    end
  end
end
