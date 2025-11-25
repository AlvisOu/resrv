require "rails_helper"

RSpec.describe PenaltiesController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers

  let(:frozen_time) { Time.zone.local(2025, 1, 1, 12, 0, 0) }
  let(:owner) { User.create!(name: "Owner", email: "owner@example.com", password: "password", email_verified_at: Time.current) }
  let(:member) { User.create!(name: "Member", email: "member@example.com", password: "password", email_verified_at: Time.current) }
  let(:workspace) { Workspace.create!(name: "Test Workspace") }
  let!(:owner_join) { UserToWorkspace.create!(user: owner, workspace: workspace, role: "owner") }
  let!(:member_join) { UserToWorkspace.create!(user: member, workspace: workspace, role: "user") }
  let(:penalty) do
    Penalty.create!(
      user: member,
      workspace: workspace,
      reason: "no_show",
      expires_at: 3.days.from_now
    )
  end

  before do
    # default to member unless overridden
    session[:user_id] = member.id
  end

  describe "POST #appeal" do
    around { |ex| travel_to(frozen_time) { ex.run } }

    it "submits an appeal and notifies the owner" do
      post :appeal, params: { id: penalty.id, appeal_message: "Please reconsider" }

      penalty.reload
      expect(penalty.appeal_state).to eq("pending")
      expect(penalty.appeal_message).to eq("Please reconsider")

      note = Notification.last
      expect(note.user).to eq(owner)
      expect(note.penalty).to eq(penalty)
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to include("Appeal sent")
    end

    it "blocks duplicate appeals" do
      penalty.update!(appeal_state: "pending")
      post :appeal, params: { id: penalty.id }

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to include("already submitted")
    end

    it "blocks appeals after resolution" do
      penalty.update!(appeal_state: "resolved")
      post :appeal, params: { id: penalty.id }

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to include("already reviewed")
    end
  end

  describe "PATCH #forgive" do
    around { |ex| travel_to(frozen_time) { ex.run } }
    before { session[:user_id] = owner.id }

    it "removes the penalty and notifies the user" do
      patch :forgive, params: { id: penalty.id }

      expect(Penalty.exists?(penalty.id)).to be_falsey

      note = Notification.last
      expect(note.user).to eq(member)
      expect(note.message).to include("removed by the workspace owner")
      expect(response).to redirect_to(notifications_path)
    end
  end

  describe "PATCH #shorten" do
    around { |ex| travel_to(frozen_time) { ex.run } }
    before { session[:user_id] = owner.id }

    it "reduces expiration, marks resolved, and notifies user" do
      old_expiry = penalty.expires_at
      patch :shorten, params: { id: penalty.id, shorten_hours: 5 }

      penalty.reload
      expect(penalty.appeal_state).to eq("resolved")
      expect(penalty.expires_at).to be < old_expiry

      note = Notification.last
      expect(note.user).to eq(member)
      expect(note.message).to include("was reduced")
      expect(response).to redirect_to(notifications_path)
    end

    it "rejects non-positive durations" do
      patch :shorten, params: { id: penalty.id, shorten_hours: 0 }

      penalty.reload
      expect(penalty.appeal_state).to eq("none")
      expect(flash[:alert]).to include("Enter a positive number")
    end
  end
end
