require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/notifications/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /mark_as_read" do
    it "returns http success" do
      get "/notifications/mark_as_read"
      expect(response).to have_http_status(:success)
    end
  end

end
