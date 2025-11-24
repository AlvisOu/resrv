class NotificationsController < ApplicationController
  before_action :require_user

  def index
    @notifications = current_user.notifications.includes(:penalty).order(created_at: :desc)
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.update(read: true)
    redirect_to notifications_path, notice: "Notification marked as read."
  end

  def mark_all_as_read
    current_user.notifications.update_all(read: true)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end

  def destroy
    notification = current_user.notifications.find(params[:id])
    notification.destroy
    redirect_to notifications_path, notice: "Notification deleted."
  end

  def delete_all
    current_user.notifications.destroy_all
    redirect_to notifications_path, notice: "All notifications deleted."
  end
end
