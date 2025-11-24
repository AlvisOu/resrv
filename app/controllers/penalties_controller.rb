class PenaltiesController < ApplicationController
  before_action :require_user
  before_action :set_penalty
  before_action :authorize_member!, only: :appeal
  before_action :authorize_owner!, only: [:forgive, :shorten]

  def appeal
    if @penalty.appeal_state == "resolved"
      return redirect_back fallback_location: profile_path, alert: "This penalty appeal was already reviewed."
    end

    if @penalty.appeal_pending?
      return redirect_back fallback_location: profile_path, alert: "You already submitted an appeal for this penalty."
    end

    @penalty.update!(
      appeal_state: "pending",
      appeal_message: params[:appeal_message],
      appealed_at: Time.current
    )

    notify_owner_of_appeal(@penalty)
    redirect_back fallback_location: profile_path, notice: "Appeal sent to the workspace owner."
  end

  def forgive
    workspace = @penalty.workspace
    penalized_user = @penalty.user

    @penalty.destroy
    notify_penalized_user(
      penalized_user,
      workspace,
      "Your penalty in #{workspace.name} was removed by the workspace owner."
    )

    redirect_back fallback_location: notifications_path, notice: "Penalty removed."
  end

  def shorten
    if @penalty.appeal_state == "resolved"
      return redirect_back fallback_location: notifications_path, alert: "This appeal has already been handled."
    end

    hours = params[:shorten_hours].to_i
    if hours <= 0
      return redirect_back fallback_location: notifications_path, alert: "Enter a positive number of hours to reduce."
    end

    new_expires_at = (@penalty.expires_at || Time.current) - hours.hours
    new_expires_at = Time.current if new_expires_at < Time.current

    @penalty.update!(
      expires_at: new_expires_at,
      appeal_state: "resolved",
      appeal_resolved_at: Time.current
    )

    notify_penalized_user(
      @penalty.user,
      @penalty.workspace,
      "Your penalty in #{@penalty.workspace.name} was reduced and now expires at #{new_expires_at.strftime('%b %-d, %Y %-I:%M %p')}."
    )

    redirect_back fallback_location: notifications_path, notice: "Penalty end time reduced."
  end

  private

  def set_penalty
    @penalty = Penalty.find(params[:id])
  end

  def authorize_member!
    return if @penalty.user == current_user

    redirect_back fallback_location: profile_path, alert: "Not authorized to appeal this penalty."
  end

  def authorize_owner!
    return if @penalty.workspace && current_user_is_owner?(@penalty.workspace)

    redirect_back fallback_location: notifications_path, alert: "Only workspace owners can update penalties."
  end

  def notify_owner_of_appeal(penalty)
    owner = penalty.workspace&.owner
    appealing_user = penalty.user
    return unless owner

    user_name = appealing_user&.name || "A member"

    Notification.create!(
      user: owner,
      penalty: penalty,
      message: "#{user_name} appealed a penalty in #{penalty.workspace.name}."
    )
  end

  def notify_penalized_user(user, workspace, message)
    return unless user && workspace

    Notification.create!(
      user: user,
      penalty: nil,
      message: message
    )
  end
end
