require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:valid_attributes) do
    { name: "Alice", email: "alice@example.com", password: "password123", password_confirmation: "password123" }
  end

  let(:invalid_attributes) do
    { name: "", email: "bad", password: "pw", password_confirmation: "different" }
  end

  let(:user) { User.create!(valid_attributes) }

  describe "GET #new" do
    it "renders the new template" do
      get :new
      expect(response).to render_template(:new)
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      it "creates a new user and redirects to root_path" do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)

        expect(session[:user_id]).to eq(User.last.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("Welcome, Alice!")
      end
    end

    context "with invalid attributes" do
      it "does not create a user and re-renders new" do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #show" do
    it "assigns current_user as @user" do
      allow(controller).to receive(:current_user).and_return(user)
      get :show
      expect(assigns(:user)).to eq(user)
    end
  end

  describe "PATCH #update" do
    before { allow(controller).to receive(:current_user).and_return(user) }

    context "with valid params" do
      it "updates the user and redirects" do
        patch :update, params: { user: { name: "Updated Name" } }
        expect(user.reload.name).to eq("Updated Name")
        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq("Profile updated successfully.")
      end
    end

    context "with invalid params" do
      it "does not update and redirects with flash" do
        patch :update, params: { user: { email: "" } }
        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq("There was a problem updating your profile.")
      end
    end
  end

  describe "DELETE #destroy" do
    before { allow(controller).to receive(:current_user).and_return(user) }

    context "when user owns workspaces" do
      it "does not destroy account" do
        workspace = Workspace.create!(name: "Owned Space")
        UserToWorkspace.create!(user: user, workspace: workspace, role: "owner")

        delete :destroy, params: { id: user.id }
        expect(User.exists?(user.id)).to be true
        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("You must delete or transfer ownership")
      end
    end

    context "when user has no owned workspaces" do
      it "destroys account and resets session" do
        delete :destroy, params: { id: user.id }
        expect(User.exists?(user.id)).to be false
        expect(session[:user_id]).to be_nil
        expect(response).to redirect_to(signup_path)
        expect(flash[:notice]).to eq("Your account has been deleted.")
      end
    end
  end
end
