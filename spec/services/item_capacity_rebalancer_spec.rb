require "rails_helper"

RSpec.describe ItemCapacityRebalancer, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.local(2025, 1, 1, 12, 0, 0) }
  let(:workspace) { Workspace.create!(name: "Coverage Lab") }
  let(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "password") }

  around { |ex| travel_to(now) { ex.run } }

  def build_reservation(item, start_offset:, duration_minutes:, quantity: 1)
    Reservation.new(
      user: user,
      item: item,
      start_time: now + start_offset.minutes,
      end_time: now + start_offset.minutes + duration_minutes.minutes,
      quantity: quantity
    ).tap { |r| r.save(validate: false) }
  end

  it "returns when item has no remaining quantity" do
    item = Item.create!(name: "Empty", quantity: 0, workspace: workspace, start_time: now, end_time: now + 8.hours)
    build_reservation(item, start_offset: 0, duration_minutes: 60)

    expect { described_class.rebalance!(item, tz: Time.zone) }.not_to change(Reservation, :count)
  end

  it "keeps reservations that fit within capacity" do
    item = Item.create!(name: "Shared", quantity: 2, workspace: workspace, start_time: now, end_time: now + 8.hours)
    res1 = build_reservation(item, start_offset: 0, duration_minutes: 60)
    res2 = build_reservation(item, start_offset: 0, duration_minutes: 60)

    described_class.rebalance!(item, tz: Time.zone)

    expect(Reservation.exists?(res1.id)).to be true
    expect(Reservation.exists?(res2.id)).to be true
  end

  it "cancels excess reservations and notifies users" do
    item = Item.create!(name: "Single", quantity: 1, workspace: workspace, start_time: now, end_time: now + 8.hours)
    keep = build_reservation(item, start_offset: 0, duration_minutes: 60, quantity: 1)
    cancel = build_reservation(item, start_offset: 0, duration_minutes: 60, quantity: 1)

    expect {
      described_class.rebalance!(item, tz: Time.zone)
    }.to change(Notification, :count).by(1)

    expect(Reservation.exists?(keep.id)).to be true
    expect(Reservation.exists?(cancel.id)).to be false
    expect(Notification.last.message).to include("was canceled because fewer copies")
  end

  it "logs and continues when notification creation fails" do
    item = Item.create!(name: "Faulty", quantity: 1, workspace: workspace, start_time: now, end_time: now + 8.hours)
    build_reservation(item, start_offset: 0, duration_minutes: 60)
    extra = build_reservation(item, start_offset: 0, duration_minutes: 60)

    allow(Notification).to receive(:create!).and_raise(StandardError.new("boom"))

    expect {
      described_class.rebalance!(item, tz: Time.zone)
    }.to change(Reservation, :count).by(-1)

    expect(Notification).to have_received(:create!).at_least(:once)
    expect(Reservation.exists?(extra.id)).to be false
  end
end
