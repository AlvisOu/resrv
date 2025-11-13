require "rails_helper"

RSpec.describe EmailVerificationsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Unverified User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  before do
    # All tests start with a clean session
    session.clear
  end

  # -------------------------------------------------------------------
  # BEFORE ACTION: find_user
  # -------------------------------------------------------------------
  describe "find_user before_action" do
    it "redirects to signup if session does not contain an unverified user" do
      get :new
      expect(response).to redirect_to(signup_path)
      expect(flash[:alert]).to eq("Invalid session. Please sign up again.")
    end
  end

  # -------------------------------------------------------------------
  # GET #new
  # -------------------------------------------------------------------
  describe "GET #new" do
    before do
      session[:unverified_user_id] = user.id
    end

    it "renders the verification form" do
      get :new
      expect(response).to render_template(:new)
      expect(assigns(:user)).to eq(user)
    end
  end

  # -------------------------------------------------------------------
  # POST #create
  # -------------------------------------------------------------------
  describe "POST #create" do
    before do
      session[:unverified_user_id] = user.id
    end

    context "when verification code is correct" do
        let(:loaded_user) { User.find(user.id) }

        before do
            session[:unverified_user_id] = user.id
            allow(User).to receive(:find_by).and_return(loaded_user)
            allow(loaded_user).to receive(:verify_email_code).and_return(true)
        end

        it "verifies email, logs in user, clears unverified session, and redirects" do
            post :create, params: { verification_code: "123456" }

            expect(loaded_user).to have_received(:verify_email_code).with("123456")
            expect(session[:unverified_user_id]).to be_nil
            expect(session[:user_id]).to eq(user.id)
            expect(response).to redirect_to(root_path)
            expect(flash[:notice]).to eq("Email verified successfully. You are now logged in.")
        end
    end

    context "when verification code is incorrect" do
      before do
        allow(user).to receive(:verify_email_code).with("wrong").and_return(false)
      end

      it "does not verify email, shows alert, re-renders form with 422" do
        post :create, params: { verification_code: "wrong" }

        expect(response.status).to eq(422)
        expect(response).to render_template(:new)
        expect(flash.now[:alert]).to eq("Invalid verification code. Please try again.")
        expect(session[:unverified_user_id]).to eq(user.id) # still present
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
