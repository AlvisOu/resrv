require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "returns http success" do
      get login_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /login" do
    it "returns http success" do
      post login_path
    end
  end

  describe "DELETE /logout" do
    it "returns http success" do
      delete logout_path
    end
  end

end
