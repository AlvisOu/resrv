require 'rails_helper'

RSpec.describe CartsController, type: :controller do
  let(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "password123", password_confirmation: "password123") }
  let(:workspace) { Workspace.create!(name: "Lab") }
  let(:item) do
    Item.create!(name: "Microscope", quantity: 2, workspace: workspace,
                 start_time: Time.zone.now.beginning_of_day + 6.hours,
                 end_time:   Time.zone.now.beginning_of_day + 17.hours)
  end
  let(:base_time) { Time.zone.now.beginning_of_day + 9.hours }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #show" do
    it "assigns workspaces and active segments from the cart" do
      mock_cart = instance_double("Cart")
      allow(mock_cart).to receive(:merged_segments_by_workspace).and_return({
        workspace => [{ item: item, start_time: Time.zone.now, end_time: Time.zone.now + 1.hour, quantity: 1 }]
      })
      allow(Cart).to receive(:load).and_return(mock_cart)

      get :show, params: { workspace_id: workspace.id }

      expect(assigns(:cart)).to eq(mock_cart)
      expect(assigns(:workspaces)).to include(workspace)
      expect(assigns(:active_workspace_id)).to eq(workspace.id)
      expect(assigns(:active_segments)).to be_an(Array)
      expect(response).to render_template(:show)
    end

    it "redirects if user not logged in" do
      allow(controller).to receive(:current_user).and_return(nil)
      get :show
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("You must be logged in to access that page.")
    end
  end

  describe "POST #checkout" do
    let(:segment) do
      {
        item: item,
        start_time: base_time + 30.minutes,
        end_time:   base_time + 90.minutes,
        quantity: 1
      }
    end

    context "with valid cart and available capacity" do
      it "creates reservations, clears workspace from cart, and redirects with notice" do
        mock_cart = instance_double("Cart")
        allow(Cart).to receive(:load).and_return(mock_cart)
        allow(mock_cart).to receive(:merged_segments_by_workspace).and_return({ workspace => [segment] })
        expect(mock_cart).to receive(:clear_workspace!).with(workspace.id)

        expect {
          post :checkout, params: { workspace_id: workspace.id }
        }.to change(Reservation, :count).by(1)

        expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
        expect(flash[:notice]).to eq("Checkout complete! Your reservations have been created.")
      end
    end

    context "when segment is invalid" do
      it "rolls back and redirects with error" do
        bad_segment = segment.merge(start_time: Time.zone.now + 2.hours, end_time: Time.zone.now + 1.hour)
        mock_cart = instance_double("Cart", merged_segments_by_workspace: { workspace => [bad_segment] })
        allow(Cart).to receive(:load).and_return(mock_cart)
        allow(mock_cart).to receive(:clear_workspace!)

        expect {
          post :checkout, params: { workspace_id: workspace.id }
        }.not_to change(Reservation, :count)

        expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
        expect(flash[:alert]).to include("Invalid time/quantity")
      end
    end

    context "when item capacity exceeded" do
      it "rolls back and flashes capacity error" do
        # One existing reservation fills all capacity
        Reservation.create!(user: user, item: item,
                    start_time: base_time + 30.minutes,
                    end_time: base_time + 90.minutes)
        Reservation.create!(user: user, item: item,
                    start_time: base_time + 30.minutes,
                    end_time: base_time + 90.minutes)

        mock_cart = instance_double("Cart", merged_segments_by_workspace: { workspace => [segment] })
        allow(Cart).to receive(:load).and_return(mock_cart)
        allow(mock_cart).to receive(:clear_workspace!)

        expect {
          post :checkout, params: { workspace_id: workspace.id }
        }.not_to change(Reservation, :count)

        expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
        expect(flash[:alert]).to include("Not enough capacity for")
      end
    end

    context "when cart is empty for workspace" do
      it "redirects immediately with alert" do
        mock_cart = instance_double("Cart", merged_segments_by_workspace: { workspace => [] })
        allow(Cart).to receive(:load).and_return(mock_cart)

        post :checkout, params: { workspace_id: workspace.id }
        expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
        expect(flash[:alert]).to eq("No items in cart for this workspace.")
      end
    end

    context "when item no longer exists" do
      it "rolls back and flashes an error" do
        deleted_item = Item.create!(name: "Temp", quantity: 1, workspace: workspace,
                                    start_time: Time.zone.now.beginning_of_day + 9.hours,
                                    end_time:   Time.zone.now.beginning_of_day + 17.hours)
        deleted_item.destroy # simulate item deleted before checkout

        base_time = Time.zone.now.beginning_of_day + 9.hours
        segment = {
          item: nil, # simulate missing item reference
          start_time: base_time + 30.minutes,
          end_time: base_time + 90.minutes,
          quantity: 1
        }

        mock_cart = instance_double("Cart")
        allow(Cart).to receive(:load).and_return(mock_cart)
        allow(mock_cart).to receive(:merged_segments_by_workspace).and_return({ workspace => [segment] })
        allow(mock_cart).to receive(:clear_workspace!)

        expect {
          post :checkout, params: { workspace_id: workspace.id }
        }.not_to change(Reservation, :count)

        expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
        expect(flash[:alert]).to include("Item no longer exists.")
      end
    end

  end
end
