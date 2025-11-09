require 'rails_helper'

RSpec.describe "EmailVerifications", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/email_verifications/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/email_verifications/create"
      expect(response).to have_http_status(:success)
    end
  end

end
