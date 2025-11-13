require 'rails_helper'

RSpec.describe "PasswordResets", type: :request do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password123") }
  let(:token) { "test_token" }

  describe "GET /password/reset" do
    it "returns http success" do
      get new_password_reset_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /password/reset" do
    it "redirects after submission" do
      post password_resets_path, params: { email: user.email }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /password/reset/:token/edit" do
    it "returns http success with valid token" do
      token = SecureRandom.urlsafe_base64
      
      user.update!(
        reset_token: token,
        reset_sent_at: Time.zone.now
      )
      get edit_password_reset_path(token)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /password/reset/:token" do
    it "redirects after password update" do
      token = SecureRandom.urlsafe_base64
      user.update!(
        reset_token: token,
        reset_sent_at: Time.zone.now
      )
      
      patch password_reset_path(token), params: { 
        password: "newpassword123", 
        password_confirmation: "newpassword123" 
      }
      expect(response).to have_http_status(:redirect)
    end
  end
end