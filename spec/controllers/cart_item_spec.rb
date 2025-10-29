require 'rails_helper'

RSpec.describe CartItemsController, type: :controller do
  let(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "password123", password_confirmation: "password123") }
  let(:workspace) { Workspace.create!(name: "Lab") }
  let(:item) { Item.create!(name: "Scope", workspace: workspace, quantity: 2, start_time: Time.zone.now.beginning_of_day + 9.hours, end_time: Time.zone.now.beginning_of_day + 17.hours) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    it "adds selections to the cart and returns JSON" do
      mock_cart = instance_double("Cart", total_count: 3)
      expect(Cart).to receive(:load).with(session, user.id).and_return(mock_cart)
      expect(mock_cart).to receive(:add!).with(hash_including("item_id" => item.id, "workspace_id" => workspace.id))

      post :create, params: {
        selections: [{ item_id: item.id, workspace_id: workspace.id, start_time: "2025-10-28T09:00:00Z", end_time: "2025-10-28T10:00:00Z", quantity: 1 }].to_json
      }

      body = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(body["ok"]).to be true
      expect(body["total"]).to eq(3)
    end

    it "redirects if user not logged in" do
      allow(controller).to receive(:current_user).and_return(nil)
      post :create
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("You must be logged in to access that page.")
    end
  end

  describe "PATCH #update" do
    it "updates a cart item and returns ok JSON" do
      mock_cart = instance_double("Cart", total_count: 5)
      allow(Cart).to receive(:load).and_return(mock_cart)
      expect(mock_cart).to receive(:update!).with("42", quantity: "2")

      patch :update, params: { id: 42, quantity: 2 }

      body = JSON.parse(response.body)
      expect(body["ok"]).to be true
      expect(body["total"]).to eq(5)
    end

    it "returns error JSON for invalid index" do
      mock_cart = instance_double("Cart")
      allow(Cart).to receive(:load).and_return(mock_cart)
      expect(mock_cart).to receive(:update!).and_raise(ArgumentError)

      patch :update, params: { id: 999, quantity: 2 }

      body = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(body["ok"]).to be false
      expect(body["error"]).to eq("Invalid cart index")
    end
  end

  describe "DELETE #destroy" do
    it "removes a cart item and returns ok JSON" do
      mock_cart = instance_double("Cart", total_count: 1)
      allow(Cart).to receive(:load).and_return(mock_cart)
      expect(mock_cart).to receive(:remove!).with("15")

      delete :destroy, params: { id: 15 }

      body = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(body["ok"]).to be true
      expect(body["total"]).to eq(1)
    end
  end

  describe "DELETE #remove_range" do
    it "removes range from cart and responds to JSON" do
      mock_cart = instance_double("Cart", total_count: 0)
      allow(Cart).to receive(:load).and_return(mock_cart)
      expect(mock_cart).to receive(:remove_range!).with(
        hash_including(
          item_id: item.id,
          workspace_id: workspace.id,
          start_time: "2025-10-28T09:00:00Z",
          end_time: "2025-10-28T10:00:00Z"
        )
      )

      delete :remove_range, params: {
        item_id: item.id,
        workspace_id: workspace.id,
        start_time: "2025-10-28T09:00:00Z",
        end_time: "2025-10-28T10:00:00Z"
      }, as: :json

      body = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(body["ok"]).to be true
      expect(body["total"]).to eq(0)
    end

    it "redirects to cart with notice when requested as HTML" do
      mock_cart = instance_double("Cart", total_count: 0)
      allow(Cart).to receive(:load).and_return(mock_cart)
      allow(mock_cart).to receive(:remove_range!)

      delete :remove_range, params: {
        item_id: item.id,
        workspace_id: workspace.id,
        start_time: "2025-10-28T09:00:00Z",
        end_time: "2025-10-28T10:00:00Z"
      }

      expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
      expect(flash[:notice]).to eq("Removed from cart.")
    end
  end
end
