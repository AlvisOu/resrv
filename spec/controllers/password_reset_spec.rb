require "rails_helper"

RSpec.describe PasswordResetsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  before do
    allow_any_instance_of(User).to receive(:send_password_reset_email)
    allow_any_instance_of(User).to receive(:send_verification_email)
  end

  # -------------------------------------------------------------------
  # GET /password_resets/new
  # -------------------------------------------------------------------
  describe "GET #new" do
    it "renders the new template" do
      get :new
      expect(response).to render_template(:new)
    end
  end

  # -------------------------------------------------------------------
  # POST /password_resets
  # -------------------------------------------------------------------
  describe "POST #create" do
    context "when user exists AND verified" do
      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:verified?).and_return(true)
      end

      it "sends password reset email and redirects with generic message" do
        expect(user).to receive(:send_password_reset_email)

        post :create, params: { email: user.email }

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("If an account with that email exists, we have sent a password reset link.")
      end
    end

    context "when user exists but NOT verified" do
      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:verified?).and_return(false)
      end

      it "sends verification email and redirects to verify email path" do
        expect(user).to receive(:send_verification_email)

        post :create, params: { email: user.email }

        expect(session[:unverified_user_id]).to eq(user.id)
        expect(response).to redirect_to(verify_email_path)
        expect(flash[:notice]).to eq("Your account is not verified. We sent a new verification code to your email.")
      end
    end

    context "when no user exists with that email" do
      it "still redirects with generic message (security)" do
        post :create, params: { email: "fake@example.com" }

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("If an account with that email exists, we have sent a password reset link.")
      end
    end
  end

  # -------------------------------------------------------------------
  # GET /password_resets/:token/edit
  # -------------------------------------------------------------------
  describe "GET #edit" do
    context "with valid token" do
      before do
        user.update!(reset_token: "valid123", reset_sent_at: 5.minutes.ago)
      end

      it "renders the edit template" do
        get :edit, params: { token: "valid123" }
        expect(response).to render_template(:edit)
        expect(assigns(:user)).to eq(user)
      end
    end

    context "when token is invalid" do
      it "redirects to new reset with alert" do
        get :edit, params: { token: "doesnotexist" }
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to eq("Password reset link is invalid or has expired.")
      end
    end

    context "when token is expired" do
      before do
        user.update!(reset_token: "oldtoken", reset_sent_at: 20.minutes.ago)
      end

      it "redirects with alert" do
        get :edit, params: { token: "oldtoken" }
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to eq("Password reset link is invalid or has expired.")
      end
    end
  end

  # -------------------------------------------------------------------
  # PATCH /password_resets/:token
  # -------------------------------------------------------------------
  describe "PATCH #update" do
    before do
      allow_any_instance_of(User).to receive(:reset_password)
    end

    context "valid token + not expired" do
      before do
        user.update!(reset_token: "valid123", reset_sent_at: 5.minutes.ago)
      end

      context "successful password reset" do
        it "logs in user and redirects to root" do
          expect_any_instance_of(User).to receive(:reset_password).with("newpass", "newpass").and_return(true)

          patch :update, params: {
            token: "valid123",
            password: "newpass",
            password_confirmation: "newpass"
          }

          expect(session[:user_id]).to eq(user.id)
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq("Password successfully reset! You are now logged in.")
        end
      end

      context "password reset fails (e.g. mismatch)" do
        it "re-renders edit with unprocessable entity" do
          expect_any_instance_of(User).to receive(:reset_password).and_return(false)

          patch :update, params: {
            token: "valid123",
            password: "x",
            password_confirmation: "y"
          }

          expect(response.status).to eq(422)
          expect(response).to render_template(:edit)
        end
      end
    end

    context "invalid token" do
      it "redirects with alert" do
        patch :update, params: {
          token: "invalid",
          password: "newpass",
          password_confirmation: "newpass"
        }

        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to eq("Password reset link is invalid or has expired.")
      end
    end

    context "expired token" do
      before do
        user.update!(reset_token: "expired", reset_sent_at: 20.minutes.ago)
      end

      it "redirects with alert" do
        patch :update, params: {
          token: "expired",
          password: "newpass",
          password_confirmation: "newpass"
        }

        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to eq("Password reset link is invalid or has expired.")
      end
    end
  end
end
