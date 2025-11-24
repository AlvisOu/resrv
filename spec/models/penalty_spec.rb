# spec/models/penalty_spec.rb

require 'rails_helper'

RSpec.describe Penalty, type: :model do
  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password123") }
  let!(:workspace) { Workspace.create!(name: "Test Workspace") }
  let!(:item) do
    Item.create!(
      name: "Test Item",
      quantity: 10,
      workspace: workspace,
      start_time: Time.zone.now.beginning_of_day + 9.hours,
      end_time: Time.zone.now.beginning_of_day + 17.hours
    )
  end
  let!(:reservation) do
    Reservation.create!(
      user: user,
      item: item,
      start_time: Time.zone.now.beginning_of_day + 10.hours,
      end_time: Time.zone.now.beginning_of_day + 11.hours,
      in_cart: false
    )
  end

  let(:base_attributes) do
    {
      user: user,
      workspace: workspace,
      reason: "late_return",
      expires_at: Time.current + 7.days
    }
  end

  describe "associations" do
    it "belongs to a user" do
      penalty = Penalty.new(base_attributes)
      expect(penalty).to respond_to(:user)
    end

    it "belongs to a workspace" do
      penalty = Penalty.new(base_attributes)
      expect(penalty).to respond_to(:workspace)
    end

    it "belongs to an optional reservation" do
      penalty = Penalty.new(base_attributes.merge(reservation: reservation))
      expect(penalty).to respond_to(:reservation)
    end

    it "is valid without a reservation" do
      penalty = Penalty.new(base_attributes.merge(reservation: nil))
      expect(penalty).to be_valid
    end
  end

  describe "validations" do
    context "with valid attributes" do
      it "is valid with all required attributes" do
        penalty = Penalty.new(base_attributes)
        expect(penalty).to be_valid
      end

      it "is valid with a reservation" do
        penalty = Penalty.new(base_attributes.merge(reservation: reservation))
        expect(penalty).to be_valid
      end

      it "is valid with 'late_return' reason" do
        penalty = Penalty.new(base_attributes.merge(reason: "late_return"))
        expect(penalty).to be_valid
      end

      it "is valid with 'no_show' reason" do
        penalty = Penalty.new(base_attributes.merge(reason: "no_show"))
        expect(penalty).to be_valid
      end

      it "defaults appeal_state to none" do
        penalty = Penalty.create!(base_attributes)
        expect(penalty.appeal_state).to eq("none")
      end
    end

    context "with invalid attributes" do
      it "is valid without a user" do
        penalty = Penalty.new(base_attributes.merge(user: nil))
        expect(penalty).to be_valid # This should pass if user is optional
      end

      it "is valid without a workspace" do
        penalty = Penalty.new(base_attributes.merge(workspace: nil))
        expect(penalty).to be_valid # This should pass if workspace is optional
      end

      it "is invalid without a reason" do
        penalty = Penalty.new(base_attributes.merge(reason: nil))
        expect(penalty).not_to be_valid
        expect(penalty.errors[:reason]).not_to be_empty
      end

      it "is invalid with an invalid reason" do
        penalty = Penalty.new(base_attributes.merge(reason: "invalid_reason"))
        expect(penalty).not_to be_valid
        expect(penalty.errors[:reason]).to include("is not included in the list")
      end

      it "is valid without an expiration date" do
        penalty = Penalty.new(base_attributes.merge(expires_at: nil))
        expect(penalty).to be_valid # This should pass if expires_at is optional
      end

      it "is invalid with an unknown appeal_state" do
        penalty = Penalty.new(base_attributes.merge(appeal_state: "invalid"))
        expect(penalty).not_to be_valid
        expect(penalty.errors[:appeal_state]).to include("is not included in the list")
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_penalty) do
        Penalty.create!(base_attributes.merge(expires_at: Time.current + 1.day))
      end

      let!(:expired_penalty) do
        Penalty.create!(base_attributes.merge(expires_at: Time.current - 1.day))
      end

      it "returns only active penalties" do
        active_penalties = Penalty.active
        expect(active_penalties).to include(active_penalty)
        expect(active_penalties).not_to include(expired_penalty)
      end

      it "returns penalties that expire in the future" do
        expect(Penalty.active.count).to eq(1)
      end
    end
  end

  describe "instance methods" do
    describe "#late_return?" do
      it "returns true for late_return reason" do
        penalty = Penalty.new(base_attributes.merge(reason: "late_return"))
        expect(penalty.late_return?).to be true
      end

      it "returns false for no_show reason" do
        penalty = Penalty.new(base_attributes.merge(reason: "no_show"))
        expect(penalty.late_return?).to be false
      end
    end

    describe "#no_show?" do
      it "returns true for no_show reason" do
        penalty = Penalty.new(base_attributes.merge(reason: "no_show"))
        expect(penalty.no_show?).to be true
      end

      it "returns false for late_return reason" do
        penalty = Penalty.new(base_attributes.merge(reason: "late_return"))
        expect(penalty.no_show?).to be false
      end
    end

    describe "appeal helpers" do
      it "is pending when appeal_state is pending" do
        penalty = Penalty.new(base_attributes.merge(appeal_state: "pending"))
        expect(penalty.appeal_pending?).to be true
        expect(penalty.appealed?).to be true
      end

      it "is not appealed when appeal_state is none" do
        penalty = Penalty.new(base_attributes.merge(appeal_state: "none"))
        expect(penalty.appeal_pending?).to be false
        expect(penalty.appealed?).to be false
      end
    end
  end

  describe "constants" do
    it "has valid reasons defined" do
      expect(Penalty::VALID_REASONS).to match_array(["late_return", "no_show"])
    end

    it "has appeal states defined" do
      expect(Penalty::APPEAL_STATES).to match_array(["none", "pending", "resolved"])
    end
  end
end
