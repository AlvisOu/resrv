require 'rails_helper'

RSpec.describe MissingReport, type: :model do
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  let(:workspace) { Workspace.create!(name: "Physics Lab") }

  let(:item) do
    Item.create!(
      name: "Oscilloscope",
      quantity: 4,
      workspace: workspace,
      start_time: Time.zone.parse("2020-01-01 09:00"),
      end_time:   Time.zone.parse("2020-01-01 17:00")
    )
  end

  let(:reservation) do
    Reservation.create!(
      user: user,
      item: item,
      quantity: 2,
      returned_count: 0,
      start_time: Time.zone.now.change(hour: 9),
      end_time:   Time.zone.now.change(hour: 10)
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      report = MissingReport.new(
        reservation: reservation,
        item: item,
        workspace: workspace,
        quantity: 1
      )
      expect(report).to be_valid
    end

    it "is invalid without a reservation" do
      report = MissingReport.new(
        reservation: nil,
        item: item,
        workspace: workspace,
        quantity: 1
      )
      expect(report).not_to be_valid
      expect(report.errors[:reservation]).to be_present
    end

    it "is invalid without an item" do
      report = MissingReport.new(
        reservation: reservation,
        item: nil,
        workspace: workspace,
        quantity: 1
      )
      expect(report).not_to be_valid
      expect(report.errors[:item]).to be_present
    end

    it "is invalid without a workspace" do
      report = MissingReport.new(
        reservation: reservation,
        item: item,
        workspace: nil,
        quantity: 1
      )
      expect(report).not_to be_valid
      expect(report.errors[:workspace]).to be_present
    end

    it "is invalid without a quantity" do
      report = MissingReport.new(
        reservation: reservation,
        item: item,
        workspace: workspace,
        quantity: nil
      )
      expect(report).not_to be_valid
      expect(report.errors[:quantity]).to be_present
    end
  end

  describe "associations" do
    it { should belong_to(:reservation) }
    it { should belong_to(:item) }
    it { should belong_to(:workspace) }
  end

  describe "default values" do
    it "is unresolved by default" do
      report = MissingReport.create!(
        reservation: reservation,
        item: item,
        workspace: workspace,
        quantity: 1
      )
      expect(report.resolved).to eq(false)
    end
  end
end
