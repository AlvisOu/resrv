require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current
    )
  end

  let!(:notification) do
    # Adjust attributes to match your Notification model
    Notification.create!(
      user: user,
      message: "Test notification",
      read: false
    )
  end

  # Helper to simulate a logged-in user in request specs
  before do
    # If your app uses session-based auth via SessionsController,
    # this will log the user in for all examples in this file.
    post login_path, params: {
      session: {
        email: user.email,
        password: "password123"
      }
    }
  end

  describe "GET /notifications" do
    it "returns http success" do
      get notifications_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /notifications/:id/mark_as_read" do
    it "marks the notification as read and redirects" do
      post mark_as_read_notification_path(notification)

      expect(response).to redirect_to(notifications_path)
      # and optionally:
      notification.reload
      expect(notification.read).to be true
    end
  end
end
