require 'rails_helper'

RSpec.describe ReservationReminderJob, type: :job do
  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password123") }
  let!(:workspace) { Workspace.create!(name: "Test Workspace") }

  let!(:item) do
    Item.create!(
      name: "Camera",
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
      quantity: 2,
      start_time: Time.zone.now.beginning_of_day + 10.hours,  # 10 AM
      end_time: Time.zone.now.beginning_of_day + 11.hours,     # 11 AM
      in_cart: false
    )
  end

  describe "#perform - start reminder" do
    it "creates a start reminder notification" do
      expect {
        described_class.perform_now(reservation.id, "start")
      }.to change(Notification, :count).by(1)

      n = Notification.last
      expect(n.message).to include("starts in 2 hours")
      expect(n.user).to eq(user)
      expect(n.reservation).to eq(reservation)
      expect(n.read).to be false
    end
  end

  describe "#perform - end reminder" do
    it "creates an end reminder notification" do
      expect {
        described_class.perform_now(reservation.id, "end")
      }.to change(Notification, :count).by(1)

      n = Notification.last
      expect(n.message).to include("ends in 10 minutes")
    end
  end

  describe "#perform - unknown reminder type" do
    it "creates a fallback reminder notification" do
      expect {
        described_class.perform_now(reservation.id, "random_type")
      }.to change(Notification, :count).by(1)

      n = Notification.last
      expect(n.message).to eq(
        "Reminder about your reservation for #{reservation.quantity}x #{item.name} in #{workspace.name}."
      )
    end
  end

  describe "#perform - reservation with no user" do
    it "does not create a notification" do
      res_no_user = Reservation.create!(
        user: nil,
        item: item,
        quantity: 1,
        start_time: Time.zone.now.beginning_of_day + 12.hours,
        end_time: Time.zone.now.beginning_of_day + 13.hours,
        in_cart: false
      )

      expect {
        described_class.perform_now(res_no_user.id, "start")
      }.not_to change(Notification, :count)
    end
  end
end