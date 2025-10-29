require 'rails_helper'

RSpec.describe ItemsController, type: :controller do
  let(:user) { User.create!(name: "Owner", email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let(:workspace) { Workspace.create!(name: "Lab A") }

  let!(:membership) { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #new" do
    it "renders the new template for owner" do
      get :new, params: { workspace_id: workspace.id }
      expect(response).to render_template(:new)
      expect(assigns(:item)).to be_a_new(Item)
    end

    it "redirects non-owner to workspace with alert" do
      membership.update!(role: "user")
      get :new, params: { workspace_id: workspace.id }
      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        workspace_id: workspace.id,
        item: {
          name: "Microscope",
          quantity: 2,
          start_time: Time.zone.now,
          end_time: Time.zone.now + 1.hour
        }
      }
    end

    it "creates item and redirects to workspace for owner" do
      expect {
        post :create, params: valid_params
      }.to change(Item, :count).by(1)

      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:notice]).to eq("Item added successfully.")
    end

    it "re-renders new on invalid data" do
      invalid_params = valid_params.deep_merge(item: { name: "" })
      post :create, params: invalid_params
      expect(response).to render_template(:new)
      expect(response.status).to eq(422)
    end

    it "redirects non-owner to workspace with alert" do
      membership.update!(role: "user")
      post :create, params: valid_params
      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  describe "GET #edit" do
    let!(:item) { Item.create!(name: "Lens", quantity: 1, workspace: workspace, start_time: Time.zone.now, end_time: Time.zone.now + 1.hour) }

    it "renders the edit template for owner" do
      get :edit, params: { workspace_id: workspace.id, id: item.id }
      expect(response).to render_template(:edit)
      expect(assigns(:item)).to eq(item)
    end

    it "redirects non-owner with alert" do
      membership.update!(role: "user")
      get :edit, params: { workspace_id: workspace.id, id: item.id }
      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  describe "PATCH #update" do
    let!(:item) { Item.create!(name: "Sensor", quantity: 1, workspace: workspace, start_time: Time.zone.now, end_time: Time.zone.now + 1.hour) }

    it "updates item successfully for owner" do
      patch :update, params: {
        workspace_id: workspace.id,
        id: item.id,
        item: { name: "Updated Sensor" }
      }

      expect(item.reload.name).to eq("Updated Sensor")
      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:notice]).to eq("Item updated successfully.")
    end

    it "re-renders edit on invalid data" do
      patch :update, params: {
        workspace_id: workspace.id,
        id: item.id,
        item: { name: "" }
      }

      expect(response).to render_template(:edit)
      expect(response.status).to eq(422)
    end

    it "redirects non-owner with alert" do
      membership.update!(role: "user")
      patch :update, params: {
        workspace_id: workspace.id,
        id: item.id,
        item: { name: "Hacked" }
      }
      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  describe "DELETE #destroy" do
    let!(:item) { Item.create!(name: "Camera", quantity: 1, workspace: workspace, start_time: Time.zone.now, end_time: Time.zone.now + 1.hour) }

    it "deletes item and redirects for owner" do
      expect {
        delete :destroy, params: { workspace_id: workspace.id, id: item.id }
      }.to change(Item, :count).by(-1)

      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:notice]).to eq("Item deleted successfully.")
    end

    it "redirects non-owner with alert" do
      membership.update!(role: "user")
      delete :destroy, params: { workspace_id: workspace.id, id: item.id }
      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end
end
