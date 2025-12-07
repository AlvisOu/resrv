require 'rails_helper'

RSpec.describe WorkspacesController, type: :controller do
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:workspace) { Workspace.create!(name: "Robotics Lab") }

  let(:empty_relation) { Penalty.none }

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive_message_chain(:penalties, :active).and_return(empty_relation)
  end

  # -------------------------------------------------------------------
  # INDEX
  # -------------------------------------------------------------------
  describe "GET #index" do
    context "when searching by query" do
      it "finds workspace by id" do
        get :index, params: { query: workspace.id.to_s }
        expect(assigns(:workspaces)).to include(workspace)
      end

      it "finds workspace by partial name (case-insensitive)" do
        get :index, params: { query: "robot" }
        expect(assigns(:workspaces)).to include(workspace)
      end
    end

    context "without query" do
      before do
        owned = Workspace.create!(name: "Owned")
        joined = Workspace.create!(name: "Joined")
        UserToWorkspace.create!(user: user, workspace: owned, role: "owner")
        UserToWorkspace.create!(user: user, workspace: joined, role: "user")

        allow(user).to receive(:owned_workspaces).and_return([owned])
        allow(user).to receive(:joined_workspaces).and_return([joined])
      end

      it "assigns owned and joined workspaces" do
        get :index
        expect(assigns(:owned_workspaces).map(&:name)).to include("Owned")
        expect(assigns(:joined_workspaces).map(&:name)).to include("Joined")
      end
    end
  end

  # -------------------------------------------------------------------
  # CREATE
  # -------------------------------------------------------------------
  describe "POST #create" do
    it "creates a new workspace and assigns ownership" do
      expect {
        post :create, params: { workspace: { name: "New Space" } }
      }.to change(Workspace, :count).by(1)
       .and change(UserToWorkspace, :count).by(1)

      ws  = Workspace.last
      rel = UserToWorkspace.last

      expect(rel.user).to eq(user)
      expect(rel.workspace).to eq(ws)
      expect(rel.role).to eq("owner")

      expect(response).to redirect_to(ws)
      expect(flash[:notice]).to eq("Workspace was successfully created.")
    end

    it "re-renders :new on invalid data" do
      post :create, params: { workspace: { name: "" } }
      expect(response).to render_template(:new)
    end
  end

  # -------------------------------------------------------------------
  # NEW
  # -------------------------------------------------------------------
  describe "GET #new" do
    it "assigns a new workspace" do
      get :new
      expect(assigns(:workspace)).to be_a_new(Workspace)
    end
  end

  # -------------------------------------------------------------------
  # SHOW
  # Full coverage for: day clamping, slots, booking_tooltips, penalties, reports
  # -------------------------------------------------------------------
  describe "GET #show" do
    before do
      allow(Time.zone).to receive(:now)
      .and_return(Time.zone.now.beginning_of_day + 12.hours)
      UserToWorkspace.create!(user: user, workspace: workspace, role: "owner")

      @item = Item.create!(
        name: "Microscope",
        quantity: 1,
        workspace: workspace,
        start_time: Time.zone.now.beginning_of_day + 9.hours,
        end_time:   Time.zone.now.beginning_of_day + 23.hours
      )

      @reservation = Reservation.create!(
        user: user,
        item: @item,
        start_time: Time.zone.now - 15.minutes,
        end_time: Time.zone.now + 15.minutes
      )

      allow_any_instance_of(Reservation).to receive(:auto_mark_missing_items)
    end

    it "assigns workspace, items, and availability data" do
      get :show, params: { id: workspace.slug }

      expect(assigns(:workspace)).to eq(workspace)
      expect(assigns(:items)).to include(@item)

      # AvailabilityService output
      expect(assigns(:availability_data)).to be_an(Array)
      expect(assigns(:availability_data).first).to have_key(:slots)

      # Slots (96 x 15-min intervals)
      expect(assigns(:slots).length).to eq(96)

      expect(response).to render_template(:show)
    end

    it "clamps requested day below today" do
      get :show, params: { id: workspace.slug, day: "1900-01-01" }
      expect(assigns(:day)).to eq(Time.zone.today)
    end

    it "clamps requested day above max_day" do
      get :show, params: { id: workspace.slug, day: (Date.today + 20).to_s }
      expect(assigns(:day)).to eq(Date.today + 7.days)
    end

    it "handles invalid date param safely" do
      get :show, params: { id: workspace.slug, day: "not-a-date" }
      expect(assigns(:day)).to eq(Date.today)
    end

    it "builds booking_tooltips for owners" do
      get :show, params: { id: workspace.slug }

      tooltips = assigns(:booking_tooltips)
      expect(tooltips).to be_a(Hash)
      expect(tooltips.keys).to include(@item.id)
    end

    it "assigns current_activity with overlaps" do
      get :show, params: { id: workspace.slug }
      expect(assigns(:current_activity)).to be_present
    end

    it "assigns resolved and unresolved missing reports" do
      mr1 = MissingReport.create!(
        item: @item,
        reservation: @reservation,
        workspace: workspace,
        quantity: 1,
        resolved: false
      )

      mr2 = MissingReport.create!(
        item: @item,
        reservation: @reservation,
        workspace: workspace,
        quantity: 1,
        resolved: true
      )

      get :show, params: { id: workspace.slug }

      expect(assigns(:unresolved_reports)).to include(mr1)
      expect(assigns(:resolved_reports)).to   include(mr2)
    end
  end

  # -------------------------------------------------------------------
  # EDIT
  # -------------------------------------------------------------------
  describe "GET #edit" do
    context "when owner" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }

      it "renders edit template" do
        get :edit, params: { id: workspace.slug }
        expect(response).to render_template(:edit)
      end
    end

    context "when not owner" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "user") }

      it "redirects to root with alert" do
        get :edit, params: { id: workspace.slug }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end
  end

  # -------------------------------------------------------------------
  # UPDATE
  # -------------------------------------------------------------------
  describe "PATCH #update" do
    context "as owner" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }

      it "updates workspace name" do
        patch :update, params: { id: workspace.slug, workspace: { name: "Updated Name" } }
        expect(workspace.reload.name).to eq("Updated Name")
        expect(response).to redirect_to(workspace_path(workspace))
        expect(flash[:notice]).to eq("Workspace updated successfully.")
      end

      it "renders :edit on invalid data" do
        patch :update, params: { id: workspace.slug, workspace: { name: "" } }
        expect(response).to render_template(:edit)
        expect(response.status).to eq(422)
      end
    end

    context "as non-owner" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "user") }

      it "redirects to root with alert" do
        patch :update, params: { id: workspace.slug, workspace: { name: "Hacked" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end
  end

  describe "GET #show trend and filters" do
    include ActiveSupport::Testing::TimeHelpers

    let(:now) { Time.zone.local(2025, 1, 15, 12, 0, 0) }
    let!(:owner_join) { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }
    let!(:item) do
      Item.create!(
        name: "Scope",
        workspace: workspace,
        quantity: 2,
        start_time: now.beginning_of_day,
        end_time: now.end_of_day
      )
    end

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow_any_instance_of(Reservation).to receive(:auto_mark_missing_items)
    end

    around { |ex| travel_to(now) { ex.run } }

    it "sets a flat trend when there is no history" do
      get :show, params: { id: workspace.slug }
      expect(assigns(:weekly_trend)).to eq(:flat)
    end

    it "detects upward and downward trends" do
      Reservation.create!(user: user, item: item, start_time: now - 1.day, end_time: now - 1.day + 1.hour)
      Reservation.create!(user: user, item: item, start_time: now - 2.days, end_time: now - 2.days + 1.hour)
      Reservation.create!(user: user, item: item, start_time: now - 10.days, end_time: now - 10.days + 1.hour)

      get :show, params: { id: workspace.slug }
      expect(assigns(:weekly_trend)).to eq(:up)

      Reservation.create!(user: user, item: item, start_time: now - 11.days, end_time: now - 11.days + 1.hour)
      Reservation.create!(user: user, item: item, start_time: now - 12.days, end_time: now - 12.days + 1.hour)
      get :show, params: { id: workspace.slug }
      expect(assigns(:weekly_trend)).to eq(:down)
    end

    it "sweeps overdue reservations and respects filter params" do
      overdue = Reservation.create!(user: user, item: item, start_time: now - 2.hours, end_time: now - 40.minutes)
      future  = Reservation.create!(user: user, item: item, start_time: now + 2.hours, end_time: now + 3.hours)

      expect_any_instance_of(Reservation).to receive(:auto_mark_missing_items).at_least(:once)

      get :show, params: { id: workspace.slug, filter_day: "bad-date", filter_item_id: item.id }

      expect(assigns(:filter_day)).to eq(Time.zone.today)
      expect(assigns(:upcoming_reservations)).to include(future)
      expect(assigns(:upcoming_reservations)).not_to include(overdue)
    end
  end

  describe "GET #past_reservations" do
    include ActiveSupport::Testing::TimeHelpers

    let(:now) { Time.zone.local(2025, 1, 15, 12, 0, 0) }

    around { |ex| travel_to(now) { ex.run } }

    before do
      UserToWorkspace.create!(user: user, workspace: workspace, role: "owner")
      allow(controller).to receive(:current_user).and_return(user)
      Item.create!(name: "Old Scope", workspace: workspace, quantity: 1, start_time: now.beginning_of_day, end_time: now.end_of_day)
    end

    it "lists past reservations in descending order" do
      past = Reservation.create!(user: user, item: workspace.items.first, start_time: now - 2.hours, end_time: now - 1.hour)

      get :past_reservations, params: { id: workspace.slug }

      expect(assigns(:past_reservations)).to include(past)
    end
  end

  describe "analytics and CSV exports" do
    include ActiveSupport::Testing::TimeHelpers

    let(:now) { Time.zone.local(2025, 1, 15, 12, 0, 0) }
    let!(:owner_join) { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }
    let!(:item) do
      Item.create!(
        name: "Microscope",
        workspace: workspace,
        quantity: 2,
        start_time: now.beginning_of_day,
        end_time: now.end_of_day
      )
    end
    let!(:untimed_item) do
      Item.new(
        name: "Untimed",
        workspace: workspace,
        quantity: 1
      ).tap { |i| i.save(validate: false) }
    end

    around { |ex| travel_to(now) { ex.run } }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      Reservation.create!(user: user, item: item, start_time: now - 1.day, end_time: now - 1.day + 1.hour, quantity: 1)
      Reservation.create!(user: user, item: item, start_time: now - 10.days, end_time: now - 10.days + 1.hour, quantity: 1, returned_count: 0)
      MissingReport.create!(item: item, reservation: Reservation.last, workspace: workspace, quantity: 1, resolved: false, reported_at: now - 10.days)
    end

    it "builds analytics data" do
      get :analytics, params: { id: workspace.slug, range: "1m", user_rank: "recency" }

      expect(assigns(:utilization).first[:item]).to eq(item)
      expect(assigns(:heatmap)[item.id].length).to eq(96)
      expect(assigns(:behavior).first[:total_res]).to eq(2)
      expect(assigns(:user_rankings)).not_to be_empty
      expect(assigns(:selected_range)).to eq("1m")
    end

    it "exports utilization, behavior, and heatmap CSVs" do
      get :analytics_utilization_csv, params: { id: workspace.slug, range: "all" }
      expect(response.header["Content-Disposition"]).to include("utilization.csv")

      get :analytics_behavior_csv, params: { id: workspace.slug }
      expect(response.header["Content-Disposition"]).to include("behavior.csv")

      get :analytics_heatmap_csv, params: { id: workspace.slug }
      expect(response.header["Content-Disposition"]).to include("heatmap.csv")
      expect(response.body).to include(item.name)
    end
  end

  describe "POST #join_by_code" do
    before do
      allow(controller).to receive(:current_user).and_return(user)
      UserToWorkspace.create!(user: user, workspace: workspace, role: "user")
    end

    it "rejects blank codes" do
      post :join_by_code, params: { join_code: "" }
      expect(response).to redirect_to(workspaces_path)
      expect(flash[:alert]).to eq("Please enter a join code.")
    end

    it "handles already-joined users" do
      workspace.update!(join_code: "ABC123")
      post :join_by_code, params: { join_code: "ABC123" }

      expect(response).to redirect_to(workspace)
      expect(flash[:notice]).to include("already a member")
    end

    it "joins with a valid code" do
      other_ws = Workspace.create!(name: "Other", join_code: "JOINME")
      post :join_by_code, params: { join_code: "JOINME" }

      expect(response).to redirect_to(other_ws)
      expect(flash[:notice]).to include("Successfully joined")
      expect(UserToWorkspace.find_by(user: user, workspace: other_ws)).not_to be_nil
    end

    it "rejects invalid codes" do
      post :join_by_code, params: { join_code: "NOTREAL" }
      expect(response).to redirect_to(workspaces_path)
      expect(flash[:alert]).to eq("Invalid join code.")
    end
  end
end
