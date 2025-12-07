require "rails_helper"

RSpec.describe CartItemsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:workspace) { Workspace.create!(name: "Lab") }
  let(:item) do
    Item.create!(
      name: "Scope",
      workspace: workspace,
      quantity: 2,
      start_time: Time.zone.now.beginning_of_day + 9.hours,
      end_time:   Time.zone.now.beginning_of_day + 17.hours
    )
  end

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
  end


  # -------------------------------------------------------------------
  # CREATE
  # -------------------------------------------------------------------
  describe "POST #create" do
    it "adds selections from JSON string" do
      mock_cart = instance_double("Cart", reservations_count: 3)
      expect(Cart).to receive(:load).with(session, user.id).and_return(mock_cart)

      expect(mock_cart).to receive(:add!).with(
        hash_including("item_id" => item.id, "workspace_id" => workspace.id)
      )

      post :create, params: {
        selections: [
          {
            item_id: item.id,
            workspace_id: workspace.id,
            start_time: "2025-10-28T09:00:00Z",
            end_time:   "2025-10-28T10:00:00Z",
            quantity: 1
          }
        ].to_json
      }

      body = JSON.parse(response.body)
      expect(body["ok"]).to eq(true)
      expect(body["total"]).to eq(3)
    end

    it "adds selections from raw array" do
      mock_cart = instance_double("Cart", reservations_count: 2)
      expect(Cart).to receive(:load).and_return(mock_cart)

      expect(mock_cart).to receive(:add!).with(hash_including("item_id" => item.id.to_s))

      post :create, params: {
        selections: [
          {
            item_id: item.id,
            workspace_id: workspace.id,
            start_time: "x",
            end_time: "y",
            quantity: 1
          }
        ]
      }
    end

    it "adds selections from nested cart_item params" do
      mock_cart = instance_double("Cart", reservations_count: 4)
      expect(Cart).to receive(:load).and_return(mock_cart)

      expect(mock_cart).to receive(:add!).with(hash_including("quantity" => "1"))

      post :create, params: {
        cart_item: {
          selections: [
            {
              item_id: item.id,
              workspace_id: workspace.id,
              start_time: "a",
              end_time: "b",
              quantity: 1
            }
          ]
        }
      }
    end

    it "handles empty selections array" do
      mock_cart = instance_double("Cart", reservations_count: 0)
      expect(Cart).to receive(:load).and_return(mock_cart)
      expect(mock_cart).not_to receive(:add!)

      post :create, params: { selections: [] }

      body = JSON.parse(response.body)
      expect(body["ok"]).to eq(true)
      expect(body["total"]).to eq(0)
    end

    it "blocks access when logged out" do
      session[:user_id] = nil
      allow(controller).to receive(:current_user).and_return(nil)

      post :create

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("You must be logged in to access that page.")
    end
  end

  # -------------------------------------------------------------------
  # UPDATE
  # -------------------------------------------------------------------
  describe "PATCH #update" do
    it "updates cart entry and returns ok JSON" do
      mock_cart = instance_double("Cart", reservations_count: 5)
      allow(Cart).to receive(:load).and_return(mock_cart)

      expect(mock_cart).to receive(:update!).with("42", quantity: "2")

      patch :update, params: { id: 42, quantity: 2 }

      body = JSON.parse(response.body)
      expect(body["ok"]).to eq(true)
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

  # -------------------------------------------------------------------
  # DESTROY
  # -------------------------------------------------------------------
  describe "DELETE #destroy" do
    it "removes a cart item and returns ok JSON" do
      mock_cart = instance_double("Cart", reservations_count: 1)
      allow(Cart).to receive(:load).and_return(mock_cart)

      expect(mock_cart).to receive(:remove!).with("15")

      delete :destroy, params: { id: 15 }

      body = JSON.parse(response.body)
      expect(body["ok"]).to eq(true)
      expect(body["total"]).to eq(1)
    end
  end

  # -------------------------------------------------------------------
  # remove_range (JSON + HTML)
  # -------------------------------------------------------------------
  describe "DELETE #remove_range" do
    let(:params_hash) do
      {
        item_id: item.id,
        workspace_id: workspace.id,
        start_time: "2025-10-28T09:00:00Z",
        end_time:   "2025-10-28T10:00:00Z"
      }
    end

    it "removes range and returns JSON" do
      mock_cart = instance_double("Cart", reservations_count: 0)
      allow(Cart).to receive(:load).and_return(mock_cart)

      expect(mock_cart).to receive(:remove_range!).with(
        hash_including(
          item_id: item.id,
          workspace_id: workspace.id,
          start_time: "2025-10-28T09:00:00Z",
          end_time: "2025-10-28T10:00:00Z"
        )
      )

      delete :remove_range, params: params_hash, as: :json

      body = JSON.parse(response.body)
      expect(body["ok"]).to eq(true)
      expect(body["total"]).to eq(0)
    end

    it "redirects with notice when via HTML" do
      mock_cart = instance_double("Cart", reservations_count: 0)
      allow(Cart).to receive(:load).and_return(mock_cart)
      allow(mock_cart).to receive(:remove_range!)

      delete :remove_range, params: params_hash

      expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
      expect(flash[:notice]).to eq("Removed from cart.")
    end

    it "handles string workspace_id" do
      mock_cart = instance_double("Cart", reservations_count: 0)
      allow(Cart).to receive(:load).and_return(mock_cart)

      expect(mock_cart).to receive(:remove_range!).with(
        hash_including(workspace_id: workspace.id.to_s)
      )

      delete :remove_range, params: params_hash.merge(workspace_id: workspace.id.to_s), as: :json
    end
  end

  describe "hold helpers" do
    let(:start_time) { Time.zone.parse("2025-10-28 09:00:00") }
    let(:end_time) { start_time + 1.hour }

    it "accumulates quantity when a hold already exists" do
      hold = Reservation.create!(
        user: user,
        item: item,
        start_time: start_time,
        end_time: end_time,
        quantity: 1,
        in_cart: true,
        hold_expires_at: 10.minutes.from_now
      )

      controller.send(:upsert_hold!, user, {
        item_id: item.id,
        workspace_id: workspace.id,
        start_time: start_time.iso8601,
        end_time: end_time.iso8601,
        quantity: 2
      })

      expect(hold.reload.quantity).to eq(3)
    end

    it "rescues errors when releasing holds" do
      allow(Reservation).to receive(:where).and_raise(StandardError.new("boom"))

      expect {
        controller.send(:release_holds!, user_id: user.id, item_id: item.id, start_time: start_time, end_time: end_time)
      }.not_to raise_error
    end
  end
end
