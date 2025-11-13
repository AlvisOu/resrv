require "rails_helper"

RSpec.describe CartsController, type: :controller do
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
      name: "Microscope",
      quantity: 2,
      workspace: workspace,
      start_time: Time.zone.now.beginning_of_day + 6.hours,
      end_time:   Time.zone.now.beginning_of_day + 17.hours
    )
  end

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:verified?).and_return(true)
    allow(CartHoldPruner).to receive(:prune!)
  end

  # -------------------------------------------------------------------
  # SHOW
  # -------------------------------------------------------------------
  describe "GET #show" do
    it "loads cart and assigns workspaces + segments" do
      mock_cart = instance_double("Cart")

      allow(Cart).to receive(:load).and_return(mock_cart)

      segments = { workspace => [{ item: item, start_time: Time.zone.now, end_time: 1.hour.from_now, quantity: 1 }] }
      allow(mock_cart).to receive(:merged_segments_by_workspace).and_return(segments)

      get :show, params: { workspace_id: workspace.id }

      expect(assigns(:cart)).to eq(mock_cart)
      expect(assigns(:workspaces)).to eq([workspace])
      expect(assigns(:active_workspace_id)).to eq(workspace.id)
      expect(assigns(:active_segments)).to eq(segments[workspace])

      expect(response).to render_template(:show)
    end

    it "sets active workspace to first workspace if none given" do
      mock_cart = instance_double("Cart")
      allow(Cart).to receive(:load).and_return(mock_cart)
      allow(mock_cart).to receive(:merged_segments_by_workspace).and_return({ workspace => [] })

      get :show

      expect(assigns(:active_workspace_id)).to eq(workspace.id)
    end

    it "redirects to login if no current_user" do
      allow(controller).to receive(:current_user).and_return(nil)

      get :show
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("You must be logged in to access that page.")
    end
  end

  # -------------------------------------------------------------------
  # CHECKOUT
  # -------------------------------------------------------------------
  describe "POST #checkout" do
    let(:mock_cart) { instance_double("Cart") }

    before do
      allow(Cart).to receive(:load).and_return(mock_cart)
    end

    it "calls CheckoutService and redirects with notice on success" do
      service = instance_double("CheckoutService", call: true, errors: [])
      expect(CheckoutService).to receive(:new).with(mock_cart, user, workspace.id).and_return(service)

      post :checkout, params: { workspace_id: workspace.id }

      expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
      expect(flash[:notice]).to eq("Checkout complete! Your reservations have been created.")
    end

    it "redirects with alert on failure" do
      service = instance_double("CheckoutService", call: false, errors: ["Bad", "Error"])
      expect(CheckoutService).to receive(:new).with(mock_cart, user, workspace.id).and_return(service)

      post :checkout, params: { workspace_id: workspace.id }

      expect(response).to redirect_to(cart_path(workspace_id: workspace.id))
      expect(flash[:alert]).to eq("Bad Error")
    end
  end
end
