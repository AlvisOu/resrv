require 'rails_helper'

RSpec.describe ReservationReminderJob, type: :job do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password", email_verified_at: Time.current) }
  let(:workspace) { Workspace.create!(name: "Test Workspace") }
  let(:item) { Item.create!(name: "Camera", workspace: workspace, quantity: 10) }
  let(:reservation) { Reservation.create!(user: user, item: item, quantity: 2, start_time: 1.hour.from_now, end_time: 3.hours.from_now) }

  it "creates a start reminder notification" do
    expect {
      ReservationReminderJob.perform_now(reservation.id, 'start')
    }.to change(Notification, :count).by(1)

    notification = Notification.last
    expect(notification.message).to include("starts in 2 hours")
    expect(notification.user).to eq(user)
  end

  it "creates an end reminder notification" do
    expect {
      ReservationReminderJob.perform_now(reservation.id, 'end')
    }.to change(Notification, :count).by(1)

    notification = Notification.last
    expect(notification.message).to include("ends in 10 minutes")
  end

  it "creates a fallback reminder notification for unknown type" do
    expect {
      ReservationReminderJob.perform_now(reservation.id, 'random')
    }.to change(Notification, :count).by(1)

    notification = Notification.last
    expect(notification.message).to include("Reminder about your reservation")
  end

  it "does not create a notification if reservation is missing" do
    expect {
      ReservationReminderJob.perform_now(0, 'start')
    }.not_to change(Notification, :count)
  end

  it "does not create a notification if reservation has no user" do
    reservation.update(user: nil)

    expect {
      ReservationReminderJob.perform_now(reservation.id, 'start')
    }.not_to change(Notification, :count)
  end
end
