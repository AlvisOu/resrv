require 'rails_helper'

RSpec.describe UserToWorkspacesController, type: :controller do
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:workspace) { Workspace.create!(name: "Test Workspace") }

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
  end

  # ---------------------------------------------------
  # POST #create
  # ---------------------------------------------------
  describe "POST #create" do
    context "when the user is not yet a member" do
      it "adds the user and redirects with success" do
        expect {
          post :create, params: { workspace_id: workspace.slug }
        }.to change(UserToWorkspace, :count).by(1)

        join = UserToWorkspace.last
        expect(join.user).to eq(user)
        expect(join.workspace).to eq(workspace)
        expect(join.role).to eq("user")

        expect(response).to redirect_to(workspace)
        expect(flash[:notice]).to eq("You have successfully joined #{workspace.name}!")
      end
    end

    context "when the user is already a member" do
      before { UserToWorkspace.create!(user: user, workspace: workspace, role: "user") }

      it "does not create a duplicate membership" do
        expect {
          post :create, params: { workspace_id: workspace.slug }
        }.not_to change(UserToWorkspace, :count)

        expect(response).to redirect_to(workspace)
        expect(flash[:alert]).to eq("You are already a member of this workspace.")
      end
    end
  end

  # ---------------------------------------------------
  # DELETE #destroy
  # ---------------------------------------------------
  describe "DELETE #destroy" do
    context "when user is a normal member" do
      let!(:join) { UserToWorkspace.create!(user: user, workspace: workspace, role: "user") }

      it "removes the join record and redirects" do
        expect {
          delete :destroy, params: { workspace_id: workspace.slug }
        }.to change(UserToWorkspace, :count).by(-1)

        expect(response).to redirect_to(workspace)
        expect(flash[:notice]).to eq("You have left #{workspace.name}.")
      end
    end

    context "when user is an owner" do
      let!(:join) { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }

      it "deletes the workspace and redirects to root" do
        expect {
          delete :destroy, params: { workspace_id: workspace.slug }
        }.to change(Workspace, :count).by(-1)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Workspace '#{workspace.name}' was permanently deleted.")
      end

      it "destroys associated UserToWorkspace records" do
        expect {
          delete :destroy, params: { workspace_id: workspace.slug }
        }.to change(UserToWorkspace, :count).by(-1)
      end
    end

    context "when user is NOT a member" do
      it "does nothing and shows alert" do
        expect {
          delete :destroy, params: { workspace_id: workspace.slug }
        }.not_to change(UserToWorkspace, :count)

        expect(response).to redirect_to(workspace)
        expect(flash[:alert]).to eq("You are not a member of this workspace.")
      end
    end
  end
end
