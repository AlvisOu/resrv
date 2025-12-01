require 'rails_helper'

RSpec.describe "Items", type: :request do
  
  # --- Setup ---
  let!(:owner) { User.create!(name: "Owner User", email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let!(:member) { User.create!(name: "Member User", email: "member@example.com", password: "password123", password_confirmation: "password123") }
  let!(:workspace) { Workspace.create!(name: "Test Workspace") }
  
  # Create the join records to define roles
  let!(:owner_join) { UserToWorkspace.create!(user: owner, workspace: workspace, role: "owner") }
  let!(:member_join) { UserToWorkspace.create!(user: member, workspace: workspace, role: "user") }

  # A helper to simulate logging in
  def login(user)
    post login_path, params: { session: { email: user.email, password: "password123" } }
  end

  # --- Authorization Tests (Testing the `require_owner` filter) ---

  context "as a regular workspace member" do
    before { login(member) }

    it "is not authorized to access GET /new" do
      get new_workspace_item_path(workspace)
      expect(response).to redirect_to(workspace_path(workspace))
    end

    it "is not authorized to POST /create" do
      post workspace_items_path(workspace), params: { item: { name: "test" } }
      expect(response).to redirect_to(workspace_path(workspace))
    end
  end

  context "as an unauthenticated user" do
    it "is not authorized to access GET /new" do
      get new_workspace_item_path(workspace)
      expect(response).to redirect_to(login_path)
    end

    it "is not authorized to POST /create" do
      post workspace_items_path(workspace), params: { item: { name: "test" } }
      expect(response).to redirect_to(login_path)
    end
  end

  # --- Happy Path Tests (User is the workspace owner) ---

  context "as the workspace owner" do
    before { login(owner) }

    let!(:item) { 
      Item.create!(
        workspace: workspace, 
        name: "Existing Item", 
        quantity: 1, 
        start_time: Time.zone.now, 
        end_time: Time.zone.now + 1.day
      ) 
    }
    
    let(:valid_params) {
      { item: { 
          name: "New Item", 
          quantity: 10, 
          start_time: Time.zone.now.beginning_of_day + 9.hours, 
          end_time: Time.zone.now.beginning_of_day + 17.hours 
        } 
      }
    }
    
    let(:invalid_params) { { item: { name: nil } } }

    describe "GET /new" do
      it "succeeds" do
        get new_workspace_item_path(workspace)
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /create" do
      context "with valid parameters" do
        it "creates a new Item" do
          expect {
            post workspace_items_path(workspace), params: valid_params
          }.to change(Item, :count).by(1)
        end

        it "redirects to the workspace with a notice" do
          post workspace_items_path(workspace), params: valid_params
          expect(response).to redirect_to(workspace_path(workspace))
          expect(flash[:notice]).to eq("Item added successfully.")
        end
      end

      context "with invalid parameters" do
        it "does not create a new Item" do
          expect {
            post workspace_items_path(workspace), params: invalid_params
          }.not_to change(Item, :count)
        end

        it "re-renders the 'new' template" do
          post workspace_items_path(workspace), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /edit" do
      it "succeeds" do
        get edit_workspace_item_path(workspace, item)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /update" do
      context "with valid parameters" do
        it "updates the requested item" do
          patch workspace_item_path(workspace, item), params: { item: { name: "Updated Name" } }
          item.reload
          expect(item.name).to eq("Updated Name")
        end

        it "redirects to the workspace with a notice" do
          patch workspace_item_path(workspace, item), params: { item: { name: "Updated Name" } }
          expect(response).to redirect_to(workspace_path(workspace))
          expect(flash[:notice]).to eq("Item updated successfully.")
        end
      end

      # context "with invalid parameters" do
      #   it "re-renders the 'edit' template" do
      #     patch workspace_item_path(workspace, item), params: invalid_params
      #     expect(response).to have_http_status(:unprocessable_entity)
      #   end
      # end
    end
  end
end

