require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:valid_attributes) do
    { name: "Alice", email: "alice@example.com", password: "password123", password_confirmation: "password123" }
  end

  let(:invalid_attributes) do
    { name: "", email: "bad", password: "pw", password_confirmation: "different" }
  end

  let(:user) { User.create!(valid_attributes) }

  # -------------------------------------------------------
  # GET #new (no authentication required)
  # -------------------------------------------------------
  describe "GET #new" do
    it "renders new template" do
      get :new
      expect(response).to render_template(:new)
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  # -------------------------------------------------------
  # POST #create (no authentication required)
  # -------------------------------------------------------
  describe "POST #create" do
    context "with valid attributes" do
      it "creates user + redirects to root" do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)

        created = User.last
        expect(session[:user_id]).to eq(created.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Welcome! You have signed up successfully.")
      end
    end

    context "with invalid attributes" do
      it "re-renders new" do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)

        expect(response.status).to eq(422)
        expect(response).to render_template(:new)
      end
    end
  end

  # -------------------------------------------------------
  # AUTHENTICATED ACTIONS
  # -------------------------------------------------------
  shared_context "logged in" do
    before do
      session[:user_id] = user.id
      allow(controller).to receive(:current_user).and_return(user)
    end
  end

  # -------------------------------------------------------
  # GET #show
  # -------------------------------------------------------
  describe "GET #show" do
    include_context "logged in"

    before do
      allow(user).to receive_message_chain(:penalties, :active, :includes).and_return([])
    end

    it "assigns @user" do
      get :show
      expect(assigns(:user)).to eq(user)
    end

    it "groups penalties by workspace and rejects nil keys" do
      real_workspace = Workspace.create!(name: "Penalty Workspace")
      real_penalty = Penalty.create!(user: user, workspace: real_workspace, reason: "no_show", expires_at: 2.days.from_now)
      orphan = instance_double(Penalty, workspace: nil, reservation: nil)

      allow(user).to receive_message_chain(:penalties, :active, :includes).and_return([real_penalty, orphan])

      get :show

      grouped = assigns(:workspace_penalties)
      expect(grouped.keys).to eq([real_workspace])
      expect(grouped[real_workspace]).to include(real_penalty)
    end
  end

  # -------------------------------------------------------
  # PATCH #update
  # -------------------------------------------------------
  describe "PATCH #update" do
    include_context "logged in"

    context "with valid params" do
      it "updates profile" do
        patch :update, params: { user: { name: "Updated Name" } }

        expect(user.reload.name).to eq("Updated Name")
        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq("Profile updated successfully.")
      end
    end

    context "with invalid params" do
      it "fails and redirects" do
        patch :update, params: { user: { email: "" } }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq("There was a problem updating your profile.")
      end
    end
  end

  # -------------------------------------------------------
  # DELETE #destroy
  # -------------------------------------------------------
  describe "DELETE #destroy" do
    include_context "logged in"

    context "when user owns workspaces" do
      it "prevents deletion" do
        ws = Workspace.create!(name: "Owned Space")
        UserToWorkspace.create!(user: user, workspace: ws, role: "owner")

        delete :destroy, params: { id: user.id }

        expect(User.exists?(user.id)).to be true
        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("You must delete or transfer ownership")
      end
    end

    context "when user has NO owned workspaces" do
      it "deletes account + resets session" do
        delete :destroy, params: { id: user.id }

        expect(User.exists?(user.id)).to be false
        expect(session[:user_id]).to be_nil
        expect(response).to redirect_to(signup_path)
        expect(flash[:notice]).to eq("Your account has been deleted.")
      end
    end
  end
end
