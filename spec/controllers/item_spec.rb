require "rails_helper"

RSpec.describe ItemsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Owner",
      email: "owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:workspace) { Workspace.create!(name: "Lab A") }
  let!(:membership) { UserToWorkspace.create!(user: user, workspace: workspace, role: "owner") }

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:verified?).and_return(true)
  end


  # -------------------------------------------------------------------
  # GET #new
  # -------------------------------------------------------------------
  describe "GET #new" do
    it "renders the new template for owner" do
      get :new, params: { workspace_id: workspace.slug }
      expect(response).to render_template(:new)
      expect(assigns(:item)).to be_a_new(Item)
    end

    it "redirects non-owner to workspace with alert" do
      membership.update!(role: "user")
      get :new, params: { workspace_id: workspace.slug }

      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  # -------------------------------------------------------------------
  # POST #create
  # -------------------------------------------------------------------
  describe "POST #create" do
    let(:valid_params) do
      {
        workspace_id: workspace.slug,
        item: {
          name: "Microscope",
          quantity: 2,
          start_time: Time.zone.now,
          end_time: Time.zone.now + 1.hour
        }
      }
    end

    it "creates item and redirects for owner" do
      expect {
        post :create, params: valid_params
      }.to change(Item, :count).by(1)

      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:notice]).to eq("Item added successfully.")
    end

    it "re-renders :new on invalid data" do
      invalid = valid_params.deep_merge(item: { name: "" })

      post :create, params: invalid
      expect(response).to render_template(:new)
      expect(response.status).to eq(422)
    end

    it "redirects non-owner with alert" do
      membership.update!(role: "user")
      post :create, params: valid_params

      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  # -------------------------------------------------------------------
  # GET #edit
  # -------------------------------------------------------------------
  describe "GET #edit" do
    let!(:item) do
      Item.create!(
        name: "Lens",
        quantity: 1,
        workspace: workspace,
        start_time: Time.zone.now.beginning_of_day,
        end_time: Time.zone.now.end_of_day
      )
    end

    before do
      # Build reservation history to trigger analytics calculations
      3.times do |i|
        Reservation.create!(
          user: user,
          item: item,
          quantity: 1,
          start_time: (1.month.ago.to_date + i.days).in_time_zone.change(hour: 10),
          end_time: (1.month.ago.to_date + i.days).in_time_zone.change(hour: 11)
        )
      end

      # Today reservation
      Reservation.create!(
        user: user,
        item: item,
        quantity: 1,
        start_time: Time.zone.now.change(hour: 10),
        end_time: Time.zone.now.change(hour: 11)
      )
    end

    it "renders edit and assigns analytics variables" do
      get :edit, params: { workspace_id: workspace.slug, id: item.slug }

      expect(response).to render_template(:edit)
      expect(assigns(:item)).to eq(item)

      expect(assigns(:current_counts)).to be_a(Hash)
      expect(assigns(:avg_counts)).to be_a(Hash)
      expect(assigns(:hours)).to eq((0..23).to_a)
      expect(assigns(:total_quantity)).to eq(item.quantity)
      expect(assigns(:busyness_index)).to be_a(Integer)
    end

    it "redirects non-owner" do
      membership.update!(role: "user")
      get :edit, params: { workspace_id: workspace.slug, id: item.slug }

      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  # -------------------------------------------------------------------
  # PATCH #update
  # -------------------------------------------------------------------
  describe "PATCH #update" do
    let!(:item) do
      Item.create!(
        name: "Sensor",
        quantity: 1,
        workspace: workspace,
        start_time: Time.zone.now,
        end_time: Time.zone.now + 1.hour
      )
    end

    it "updates item successfully" do
      patch :update, params: {
        workspace_id: workspace.slug,
        id: item.slug,
        item: { name: "Updated Sensor" }
      }

      expect(item.reload.name).to eq("Updated Sensor")
      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:notice]).to eq("Item updated successfully.")
    end

    it "re-renders edit on invalid data" do
      patch :update, params: {
        workspace_id: workspace.slug,
        id: item.slug,
        item: { name: "" }
      }

      expect(response).to render_template(:edit)
      expect(response.status).to eq(422)
    end

    it "redirects non-owner" do
      membership.update!(role: "user")

      patch :update, params: {
        workspace_id: workspace.slug,
        id: item.slug,
        item: { name: "Hacked" }
      }

      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  # -------------------------------------------------------------------
  # DELETE #destroy
  # -------------------------------------------------------------------
  describe "DELETE #destroy" do
    let!(:item) do
      Item.create!(
        name: "Camera",
        quantity: 1,
        workspace: workspace,
        start_time: Time.zone.now,
        end_time: Time.zone.now + 1.hour
      )
    end

    it "destroys the item for owner" do
      expect {
        delete :destroy, params: { workspace_id: workspace.slug, id: item.slug }
      }.to change(Item, :count).by(-1)

      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:notice]).to eq("Item deleted successfully.")
    end

    it "redirects non-owner" do
      membership.update!(role: "user")

      delete :destroy, params: { workspace_id: workspace.slug, id: item.slug }
      expect(response).to redirect_to(workspace_path(workspace))
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end
end
