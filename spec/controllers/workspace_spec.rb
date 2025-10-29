require 'rails_helper'

RSpec.describe WorkspacesController, type: :controller do
  let(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "password123", password_confirmation: "password123") }
  let(:workspace) { Workspace.create!(name: "Robotics Lab") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

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
      end

      it "assigns owned and joined workspaces" do
        get :index
        expect(assigns(:owned_workspaces).map(&:name)).to include("Owned")
        expect(assigns(:joined_workspaces).map(&:name)).to include("Joined")
      end
    end
  end

  describe "POST #create" do
    it "creates a new workspace and assigns ownership" do
      expect {
        post :create, params: { workspace: { name: "New Space" } }
      }.to change(Workspace, :count).by(1)
       .and change(UserToWorkspace, :count).by(1)

      ws = Workspace.last
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

  describe "GET #new" do
    it "assigns a new workspace" do
      get :new
      expect(assigns(:workspace)).to be_a_new(Workspace)
    end
  end

  describe "GET #show" do
    before do
      UserToWorkspace.create!(user: user, workspace: workspace, role: "owner")
      item = Item.create!(name: "Microscope", quantity: 1, workspace: workspace,
                          start_time: Time.zone.now.beginning_of_day + 9.hours,
                          end_time: Time.zone.now.beginning_of_day + 17.hours)
      Reservation.create!(user: user, item: item,
                          start_time: item.start_time + 30.minutes,
                          end_time: item.start_time + 60.minutes)
    end

    it "assigns workspace, items, and availability data" do
      get :show, params: { id: workspace.id }
      expect(assigns(:workspace)).to eq(workspace)
      expect(assigns(:items)).to all(be_a(Item))
      expect(assigns(:availability_data)).to be_a(Array)
      expect(assigns(:availability_data).first).to have_key(:slots)
      expect(response).to render_template(:show)
    end
  end

  describe "GET #edit" do
    context "when current user is owner" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }

      it "renders the edit template" do
        get :edit, params: { id: workspace.id }
        expect(response).to render_template(:edit)
      end
    end

    context "when not owner" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "user") }

      it "redirects to root with alert" do
        get :edit, params: { id: workspace.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end
  end

  describe "PATCH #update" do
    context "as owner" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }

      it "updates workspace name" do
        patch :update, params: { id: workspace.id, workspace: { name: "Updated Name" } }
        expect(workspace.reload.name).to eq("Updated Name")
        expect(response).to redirect_to(workspace_path(workspace))
        expect(flash[:notice]).to eq("Workspace name updated.")
      end

      it "renders :edit on invalid data" do
        patch :update, params: { id: workspace.id, workspace: { name: "" } }
        expect(response).to render_template(:edit)
        expect(response.status).to eq(422)
      end
    end

    context "as non-owner" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "user") }

      it "redirects to root with alert" do
        patch :update, params: { id: workspace.id, workspace: { name: "Hacked" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end
  end
end
