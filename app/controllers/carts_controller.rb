class CartsController < ApplicationController
  skip_forgery_protection
  before_action :require_login!

  def show
    @cart = Cart.load(session, current_user.id)
    groups = @cart.merged_segments_by_workspace
    @workspaces = groups.keys.compact
    @active_workspace_id = params[:workspace_id]&.to_i || @workspaces.first&.id
    @active_segments = groups.find { |w, _| w&.id == @active_workspace_id }&.last || []
  end

  def checkout
    @cart = Cart.load(session, current_user.id)
    workspace_id = params[:workspace_id].to_i
    groups = @cart.merged_segments_by_workspace
    workspace = groups.keys.compact.find { |w| w.id == workspace_id }
    segments  = groups[workspace] || []

    if segments.blank?
      return redirect_to cart_path(workspace_id: workspace_id), alert: "Nothing to checkout for this workspace."
    end

    errors = []

    ActiveRecord::Base.transaction do
      segments.each do |seg|
        item = seg[:item]
        s    = seg[:start_time]
        e    = seg[:end_time]
        q    = seg[:quantity].to_i

        if item.nil?
          errors << "Item no longer exists."
          raise ActiveRecord::Rollback
        end
        if s.blank? || e.blank? || s >= e || q <= 0
          errors << "Invalid time/quantity for #{item.name}."
          raise ActiveRecord::Rollback
        end

        # Re-validate capacity against existing reservations (overlap test)
        # Overlap if existing.start < e AND existing.end > s
        existing = Reservation.
          where(item_id: item.id).
          where("start_time < ? AND end_time > ?", e, s).
          count

        if existing + q > item.quantity.to_i
          errors << "Not enough capacity for #{item.name} between #{s.in_time_zone.strftime('%-I:%M %p')}–#{e.in_time_zone.strftime('%-I:%M %p')}."
          raise ActiveRecord::Rollback
        end

        # Create one Reservation per unit of quantity
        q.times do
          Reservation.create!(
            user_id:  current_user.id,
            item_id:  item.id,
            start_time: s,
            end_time:   e
          )
        end
      end

      # If we got here, all segments created; clear only this workspace from cart
      @cart.clear_workspace!(workspace_id)
    end

    if errors.present?
      redirect_to cart_path(workspace_id: workspace_id), alert: errors.uniq.join(" ")
    else
      redirect_to cart_path(workspace_id: workspace_id), notice: "Checkout complete! Your reservations have been created."
    end
  end

  private

  def require_login!
    redirect_to root_path, alert: "Please sign in first." unless current_user
  end
end
