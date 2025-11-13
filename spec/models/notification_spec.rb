require 'rails_helper'

RSpec.describe Notification, type: :model do
  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password123") }
  let!(:workspace) { Workspace.create!(name: "Test Workspace") }
  
  let!(:item) do
    Item.create!(
      name: "Test Item",
      quantity: 10,
      workspace: workspace,
      start_time: Time.zone.now.beginning_of_day + 9.hours,  # 9 AM
      end_time: Time.zone.now.beginning_of_day + 17.hours    # 5 PM
    )
  end

  let!(:reservation) do
    Reservation.create!(
      user: user,
      item: item,
      start_time: Time.zone.now.beginning_of_day + 10.hours,  # 10 AM
      end_time: Time.zone.now.beginning_of_day + 11.hours,    # 11 AM
      in_cart: false  # Required by your scope
    )
  end

  let(:base_attributes) do
    {
      user: user,
      reservation: reservation,
      message: "Your reservation is confirmed.",
      read: false
    }
  end

  describe "associations" do
    it "belongs to a user" do
      notification = Notification.new(base_attributes)
      expect(notification).to respond_to(:user)
    end

    it "belongs to a reservation" do
      notification = Notification.new(base_attributes)
      expect(notification).to respond_to(:reservation)
    end
  end

  describe "validations" do
    context "with valid attributes" do
      it "is valid" do
        notification = Notification.new(base_attributes)
        expect(notification).to be_valid
      end
    end

    context "with invalid attributes" do
      it "is invalid without a user" do
        notification = Notification.new(base_attributes.merge(user: nil))
        expect(notification).not_to be_valid
        expect(notification.errors[:user]).not_to be_empty
      end

      it "is invalid without a reservation" do
        notification = Notification.new(base_attributes.merge(reservation: nil))
        expect(notification).not_to be_valid
        expect(notification.errors[:reservation]).not_to be_empty
      end
    end
  end

  describe "scopes" do
    describe ".unread" do
      before do
        # Create test notifications within the before block to ensure proper setup
        Notification.create!(base_attributes.merge(read: true))
        Notification.create!(base_attributes.merge(read: false))
      end

      it "returns only unread notifications" do
        unread_notifications = Notification.unread
        expect(unread_notifications.where(read: true).count).to eq(0)
        expect(unread_notifications.where(read: false).count).to be > 0
      end

      it "returns the correct count of unread notifications" do
        expect(Notification.unread.count).to eq(1)
      end
    end
  end

  describe "default values" do
    it "defaults 'read' to false on a new record" do
      notification = Notification.new(
        user: user,
        reservation: reservation,
        message: "A new message"
      )
      
      expect(notification.read).to be false
    end
    
    it "saves with 'read' as false if not specified" do
      notification = Notification.create!(
        user: user,
        reservation: reservation,
        message: "A new message"
      )
      
      expect(notification.reload.read).to be false
    end
  end
end