require "rails_helper"

RSpec.describe MissingReportsController, type: :controller do
  let(:owner) do
    User.create!(
      name: "Owner",
      email: "owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:non_owner) do
    User.create!(
      name: "User",
      email: "user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:workspace) { Workspace.create!(name: "Robotics Lab") }

  let!(:owner_join) do
    UserToWorkspace.create!(user: owner, workspace: workspace, role: "owner")
  end

  let!(:item) do
    Item.create!(
      name: "Camera",
      quantity: 5,
      workspace: workspace,
      start_time: Time.zone.parse("2020-01-01 09:00"),
      end_time:   Time.zone.parse("2020-01-01 17:00")
    )
  end

  let!(:reservation) do
    Reservation.create!(
      user: owner,
      item: item,
      start_time: Time.zone.now.change(hour: 9),
      end_time:   Time.zone.now.change(hour: 10),
      quantity: 3,
      returned_count: 1
    )
  end

  before do
    session[:user_id] = owner.id
    allow(controller).to receive(:current_user).and_return(owner)
    allow(owner).to receive(:verified?).and_return(true)
  end


  # -------------------------------------------------------------------
  # AUTHORIZATION
  # -------------------------------------------------------------------
  describe "authorization" do
    it "redirects non-owner users" do
      # simulate logged-in non-owner
      session[:user_id] = non_owner.id
      allow(controller).to receive(:current_user).and_return(non_owner)
      allow(non_owner).to receive(:verified?).and_return(true)

      get :index, params: { workspace_id: workspace.id }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  # -------------------------------------------------------------------
  # INDEX
  # -------------------------------------------------------------------
  describe "GET #index" do
    let!(:resolved_report) do
      MissingReport.create!(
        reservation: reservation,
        item: item,
        workspace: workspace,
        quantity: 1,
        resolved: true
      )
    end

    let!(:unresolved_report) do
      MissingReport.create!(
        reservation: reservation,
        item: item,
        workspace: workspace,
        quantity: 1,
        resolved: false
      )
    end

    it "assigns resolved and unresolved reports" do
      get :index, params: { workspace_id: workspace.id }

      expect(assigns(:unresolved_reports)).to include(unresolved_report)
      expect(assigns(:resolved_reports)).to include(resolved_report)
      expect(response).to render_template(:index)
    end
  end

  # -------------------------------------------------------------------
  # CREATE
  # -------------------------------------------------------------------
  describe "POST #create" do
    context "when missing quantity > 0" do
      it "creates a missing report and decrements item quantity" do
        expect {
          post :create, params: {
            workspace_id: workspace.id,
            reservation_id: reservation.id
          }
        }.to change(MissingReport, :count).by(1)

        expect(item.reload.quantity).to eq(3) # 5 original - missing_qty(2)
        expect(response).to redirect_to(reservation_path(reservation))
        expect(flash[:notice]).to eq("Missing item reported.")
      end
    end

    context "when missing quantity == 0" do
      before { reservation.update!(returned_count: 3) } # full return

      it "does not create a missing report and flashes alert" do
        expect {
          post :create, params: {
            workspace_id: workspace.id,
            reservation_id: reservation.id
          }
        }.not_to change(MissingReport, :count)

        expect(response).to redirect_to(reservation_path(reservation))
        expect(flash[:alert]).to eq("No missing quantity to report.")
      end
    end
  end

  # -------------------------------------------------------------------
  # RESOLVE
  # -------------------------------------------------------------------
  describe "PATCH #resolve" do
    let!(:report) do
      MissingReport.create!(
        reservation: reservation,
        item: item,
        workspace: workspace,
        quantity: 2,
        resolved: false
      )
    end

    it "increments item quantity by outstanding missing qty and marks report resolved" do
      # missing qty = quantity(3) - returned_count(1) = 2
      expect {
        patch :resolve, params: {
          workspace_id: workspace.id,
          id: report.id
        }
      }.to change { report.reload.resolved }.from(false).to(true)

      expect(item.reload.quantity).to eq(7) # 5 original + 2 restored
      expect(response).to redirect_to(workspace_missing_reports_path(workspace))
      expect(flash[:notice]).to eq("Item marked as back online.")
    end

    it "raises error when trying to resolve another workspace's report" do
      other_workspace = Workspace.create!(name: "Other Lab")
      MissingReport.create!(
        reservation: reservation,
        item: item,
        workspace: other_workspace,
        quantity: 2,
        resolved: false
      )
      expect {
        patch :resolve, params: { workspace_id: workspace.id, id: MissingReport.last.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
