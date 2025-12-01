# ./spec/requests/users_spec.rb
# Signup request specs
require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /signup" do
    it "returns http success" do
      get signup_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /users" do
    # Context 1: The "happy path" (everything works)
    context "with valid parameters" do
      let(:valid_params) do
        { user: {
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "creates a new User" do
        expect {
          post users_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "redirects appropriately after signup" do
        post users_path, params: valid_params
        expect(session[:user_id]).to eq(User.last.id)
        expect(response).to redirect_to(root_path)
      end
    end

    # Context 2: The "sad path" (user provides bad data)
    context "with invalid parameters" do
      let(:invalid_params) do
        { user: {
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            password_confirmation: "WRONG"
          }
        }
      end

      it "does not create a new User" do
        expect {
          post users_path, params: invalid_params
        }.not_to change(User, :count)
      end

      it "re-renders the 'new' template with an error status" do
        post users_path, params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

end
