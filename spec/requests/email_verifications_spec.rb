require "rails_helper"

RSpec.describe "EmailVerifications", type: :request do
  describe "GET /email/verify" do
    it "redirects to signup when no unverified session exists" do
      get verify_email_path
      expect(response).to redirect_to(signup_path)
      expect(flash[:alert]).to eq("Invalid session. Please sign up again.")
    end
  end

  describe "POST /email/verify" do
    it "redirects to signup when no unverified session exists" do
      post verify_email_path, params: { verification_code: "123456" }
      expect(response).to redirect_to(signup_path)
      expect(flash[:alert]).to eq("Invalid session. Please sign up again.")
    end
  end
end
