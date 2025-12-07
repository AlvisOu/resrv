require "rails_helper"

RSpec.describe WorkspaceUsersController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.local(2025, 1, 1, 12, 0, 0) }
  let(:owner) { User.create!(name: "Owner", email: "owner@example.com", password: "password") }
  let(:member) { User.create!(name: "Member", email: "member@example.com", password: "password") }
  let(:workspace) { Workspace.create!(name: "Robotics Lab") }
  let!(:owner_join) { UserToWorkspace.create!(user: owner, workspace: workspace, role: "owner") }
  let!(:member_join) { UserToWorkspace.create!(user: member, workspace: workspace, role: "user") }

  let(:item_a) do
    Item.create!(
      name: "Scope",
      quantity: 2,
      workspace: workspace,
      start_time: now.beginning_of_day,
      end_time: now.end_of_day
    )
  end

  let(:item_b) do
    Item.create!(
      name: "Sensor",
      quantity: 3,
      workspace: workspace,
      start_time: now.beginning_of_day,
      end_time: now.end_of_day
    )
  end

  around { |ex| travel_to(now) { ex.run } }

  before do
    session[:user_id] = owner.id
    allow(controller).to receive(:current_user).and_return(owner)
    allow(controller).to receive(:current_user_is_owner?).and_return(true)
  end

  describe "GET #show" do
    before do
      # Active reservation
      Reservation.create!(
        user: member,
        item: item_a,
        start_time: now - 30.minutes,
        end_time: now + 30.minutes,
        quantity: 1,
        returned_count: 1
      )

      # Upcoming reservations (one marked no-show)
      Reservation.create!(
        user: member,
        item: item_a,
        start_time: now + 2.hours,
        end_time: now + 3.hours,
        quantity: 1
      )

      Reservation.create!(
        user: member,
        item: item_a,
        start_time: now + 4.hours,
        end_time: now + 5.hours,
        quantity: 1,
        no_show: true
      )

      # Past reservation fully returned (should not count as late)
      Reservation.create!(
        user: member,
        item: item_b,
        start_time: now - 5.hours,
        end_time: now - 4.hours,
        quantity: 1,
        returned_count: 1
      )

      # Past reservation with missing returns (counts as late_return)
      late_res = Reservation.create!(
        user: member,
        item: item_b,
        start_time: now - 3.hours,
        end_time: now - 2.hours,
        quantity: 2,
        returned_count: 1
      )

      MissingReport.create!(
        item: item_b,
        reservation: late_res,
        workspace: workspace,
        quantity: 1,
        resolved: false
      )
    end

    it "computes reservation metrics and usage for a workspace member" do
      get :show, params: { workspace_id: workspace.slug, id: member.slug }

      expect(assigns(:total_reservations)).to eq(5)
      expect(assigns(:active_reservations).count).to eq(1)
      expect(assigns(:upcoming_reservations).count).to eq(2)
      expect(assigns(:past_reservations).count).to eq(2)
      expect(assigns(:no_show_count)).to eq(1)
      expect(assigns(:late_return_count)).to eq(1)
      expect(assigns(:missing_events_count)).to eq(1)

      usage = assigns(:item_usage).to_h
      expect(usage[item_a.name]).to eq(3)
      expect(usage[item_b.name]).to eq(2)

      expect(assigns(:avg_duration)).to be > 0
      expect(assigns(:reliability_score)).to eq(0.6)
    end

    it "defaults reliability to 1.0 when there are no reservations" do
      new_user = User.create!(name: "Brand New", email: "brand_new@example.com", password: "password")

      get :show, params: { workspace_id: workspace.slug, id: new_user.slug }

      expect(assigns(:total_reservations)).to eq(0)
      expect(assigns(:reliability_score)).to eq(1.0)
    end

    it "redirects non-owners" do
      allow(controller).to receive(:current_user_is_owner?).and_return(false)

      get :show, params: { workspace_id: workspace.slug, id: member.slug }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end
end
