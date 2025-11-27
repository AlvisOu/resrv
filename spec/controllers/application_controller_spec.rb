require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: "Hello World"
    end

    def protected_action
      require_user
      render plain: "Protected" unless performed?
    end
  end

  let(:user) { User.create!(name: "Test", email: "test@example.com", password: "pw", email_verified_at: Time.now) }

  describe "#current_user" do
    it "returns nil if not logged in" do
      expect(controller.current_user).to be_nil
    end

    it "returns the user if logged in" do
      session[:user_id] = user.id
      expect(controller.current_user).to eq(user)
    end
  end

  describe "#logged_in?" do
    it "returns false if not logged in" do
      expect(controller.logged_in?).to be false
    end

    it "returns true if logged in" do
      session[:user_id] = user.id
      expect(controller.logged_in?).to be true
    end
  end

  describe "#require_user" do
    before do
      routes.draw do
        get "protected_action" => "anonymous#protected_action"
        get "login" => "sessions#new", as: :login
        get "verify_email" => "email_verifications#new", as: :verify_email
      end
    end

    it "redirects to login if not logged in" do
      get :protected_action
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to include("must be logged in")
    end

    it "redirects to verify email if logged in but unverified" do
      unverified_user = User.create!(name: "Unverified", email: "u@example.com", password: "pw")
      session[:user_id] = unverified_user.id
      
      get :protected_action
      expect(response).to redirect_to(verify_email_path)
      expect(flash[:alert]).to include("verify your email")
      expect(session[:unverified_user_id]).to eq(unverified_user.id)
      expect(session[:user_id]).to be_nil
    end

    it "allows access if logged in and verified" do
      session[:user_id] = user.id
      get :protected_action
      expect(response.body).to eq("Protected")
    end
  end

  describe "#current_user_is_owner?" do
    let(:workspace) { Workspace.create!(name: "Lab") }

    it "returns false if not logged in" do
      expect(controller.current_user_is_owner?(workspace)).to be_falsey
    end

    it "returns false if logged in but not a member" do
      session[:user_id] = user.id
      expect(controller.current_user_is_owner?(workspace)).to be_falsey
    end

    it "returns false if logged in as a regular user" do
      session[:user_id] = user.id
      UserToWorkspace.create!(user: user, workspace: workspace, role: "user")
      expect(controller.current_user_is_owner?(workspace)).to be false
    end

    it "returns true if logged in as owner" do
      session[:user_id] = user.id
      UserToWorkspace.create!(user: user, workspace: workspace, role: "owner")
      expect(controller.current_user_is_owner?(workspace)).to be true
    end
  end
end
