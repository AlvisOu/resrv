require "rails_helper"

RSpec.describe NotificationsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Bob",
      email: "bob@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:notification1) do
    Notification.create!(
      user: user,
      message: "Test 1",
      read: false,
      created_at: 2.hours.ago
    )
  end

  let!(:notification2) do
    Notification.create!(
      user: user,
      message: "Test 2",
      read: false,
      created_at: 1.hour.ago
    )
  end

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
  end

  # -------------------------------------------------------------------
  # INDEX
  # -------------------------------------------------------------------
  describe "GET #index" do
    it "assigns user's notifications in descending order" do
      get :index

      expect(assigns(:notifications)).to eq([notification2, notification1])
      expect(response).to render_template(:index)
    end

    it "redirects when not logged in" do
      allow(controller).to receive(:current_user).and_return(nil)

      get :index
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("You must be logged in to access that page.")
    end
  end

  # -------------------------------------------------------------------
  # MARK AS READ
  # -------------------------------------------------------------------
  describe "PATCH #mark_as_read" do
    it "marks a single notification as read" do
      patch :mark_as_read, params: { id: notification1.id }
      expect(notification1.reload.read).to eq(true)
      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to eq("Notification marked as read.")
    end

    it "raises error when accessing another user's notification" do
      other_notification = Notification.create!(
        user: other_user,
        message: "Not yours",
        read: false
      )

      expect {
        patch :mark_as_read, params: { id: other_notification.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # -------------------------------------------------------------------
  # MARK ALL AS READ
  # -------------------------------------------------------------------
  describe "PATCH #mark_all_as_read" do
    it "marks all notifications as read" do
      patch :mark_all_as_read

      expect(user.notifications.pluck(:read)).to all(eq(true))
      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to eq("All notifications marked as read.")
    end
  end

  # -------------------------------------------------------------------
  # DESTROY (single)
  # -------------------------------------------------------------------
  describe "DELETE #destroy" do
    it "deletes a single notification" do
      expect {
        delete :destroy, params: { id: notification1.id }
      }.to change(Notification, :count).by(-1)

      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to eq("Notification deleted.")
    end

    it "raises error when deleting another user's notification" do
      other_notification = Notification.create!(
        user: other_user,
        message: "Not yours",
        read: false
      )

      expect {
        delete :destroy, params: { id: other_notification.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # -------------------------------------------------------------------
  # DELETE ALL
  # -------------------------------------------------------------------
  describe "DELETE #delete_all" do
    it "deletes all notifications for the current user" do
      expect {
        delete :delete_all
      }.to change(Notification, :count).by(-2)

      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to eq("All notifications deleted.")
    end

    it "does not delete notifications belonging to other users" do
      Notification.create!(user: other_user, message: "Other", read: false)

      delete :delete_all

      expect(other_user.notifications.count).to eq(1)
    end
  end
end
