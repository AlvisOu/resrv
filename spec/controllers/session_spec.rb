require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # -------------------------------------------------------------------
  # GET #new
  # -------------------------------------------------------------------
  describe "GET #new" do
    it "renders login page" do
      get :new
      expect(response).to render_template(:new)
    end
  end

  # -------------------------------------------------------------------
  # POST #create (login)
  # -------------------------------------------------------------------
  describe "POST #create" do
    context "with valid credentials" do
      it "logs in and redirects to root" do
        post :create, params: {
          session: { email: user.email, password: "password123" }
        }

        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Logged in successfully.")
      end
    end

    context "with invalid password" do
      it "renders new with 422" do
        post :create, params: {
          session: { email: user.email, password: "wrong" }
        }

        expect(session[:user_id]).to be_nil
        expect(response.status).to eq(422)
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("Invalid email or password.")
      end
    end

    context "with nonexistent email" do
      it "renders new with generic error" do
        post :create, params: {
          session: { email: "doesnotexist@example.com", password: "whatever" }
        }

        expect(response.status).to eq(422)
        expect(flash[:alert]).to eq("Invalid email or password.")
      end
    end
  end

  # -------------------------------------------------------------------
  # DELETE #destroy (logout)
  # -------------------------------------------------------------------
  describe "DELETE #destroy" do
    before do
      session[:user_id] = user.id
    end

    it "logs out and redirects to login" do
      delete :destroy

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to eq("Logged out successfully.")
    end
  end
end
