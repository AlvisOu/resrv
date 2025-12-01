# ./spec/requests/sessions_spec.rb
# Login request specs
require 'rails_helper'

RSpec.describe "Sessions", type: :request do

  let!(:user) {
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  }

  describe "GET /login" do
    it "returns http success" do
      get login_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      let(:valid_params) do
        { session: {
            email: "test@example.com",
            password: "password123"
          }
        }
      end

      it "logs the user in and redirects" do
        post login_path, params: valid_params

        # Check that the session is set
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid credentials" do
      let(:invalid_params) do
        { session: {
            email: "wrong@example.com",
            password: "wrongpassword"
          }
        }
      end

      it "does not log the user in" do
        post login_path, params: invalid_params

        # Check that the session is not set
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /logout" do
    it "logs the user out and redirects" do
      # Log a user in first to have a session to destroy
      post login_path, params: { session: { email: user.email, password: "password123" } }
      expect(session[:user_id]).to eq(user.id)

      # Now, log out
      delete logout_path

      # Check that the session is empty
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(login_path)
    end
  end
end