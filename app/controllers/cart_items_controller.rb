class CartItemsController < ApplicationController
  skip_forgery_protection
  before_action :require_login!

  def create
    cart = Cart.load(session, current_user.id)
    raw  = params[:selections] || params.dig(:cart_item, :selections) || []
    raw  = JSON.parse(raw) if raw.is_a?(String)
    selections = Array(raw).map { |attrs| permit_entry(attrs) }

    # 1) Keep your session cart behavior
    selections.each { |attrs| cart.add!(attrs) }

    # 2) Also place/refresh DB holds (10 min TTL)
    selections.each { |attrs| upsert_hold!(current_user, attrs) }

    render json: { ok: true, total: cart.total_count }
  end

  def update
    cart = Cart.load(session, current_user.id)
    cart.update!(params[:id], quantity: params[:quantity])
    render json: { ok: true, total: cart.total_count }
  rescue ArgumentError
    render json: { ok: false, error: "Invalid cart index" }, status: :unprocessable_entity
  end

  def destroy
    cart = Cart.load(session, current_user.id)
    cart.remove!(params[:id])
    render json: { ok: true, total: cart.total_count }
  end

  def remove_range
    cart = Cart.load(session, current_user.id)
    cart.remove_range!(
      item_id: params[:item_id],
      workspace_id: params[:workspace_id],
      start_time: params[:start_time],
      end_time: params[:end_time]
    )

    # Also release matching holds for this user/range
    release_holds!(
      user_id: current_user.id,
      item_id: params[:item_id],
      start_time: params[:start_time],
      end_time: params[:end_time]
    )

    respond_to do |format|
      format.html { redirect_to cart_path(workspace_id: params[:workspace_id]), notice: "Removed from cart." }
      format.json { render json: { ok: true, total: cart.total_count } }
    end
  end

  private
  def upsert_hold!(user, attrs)
    item_id     = attrs[:item_id]
    start_time  = Time.iso8601(attrs[:start_time])
    end_time    = Time.iso8601(attrs[:end_time])
    quantity    = attrs[:quantity].to_i.nonzero? || 1

    hold = Reservation.where(
      user_id: user.id,
      item_id: item_id,
      start_time: start_time,
      end_time: end_time,
      in_cart: true
    ).order(id: :desc).first

    if hold.present?
      # refresh TTL and quantity
      hold.update!(
        quantity: quantity,
        hold_expires_at: 10.minutes.from_now
      )
    else
      Reservation.create!(
        user_id: user.id,
        item_id: item_id,
        start_time: start_time,
        end_time: end_time,
        quantity: quantity,
        in_cart: true,
        hold_expires_at: 10.minutes.from_now
      )
    end
  rescue => e
    Rails.logger.warn("Hold upsert failed: #{e.class}: #{e.message}")
  end

  def release_holds!(user_id:, item_id:, start_time:, end_time:)
    s = start_time.is_a?(String) ? Time.iso8601(start_time) : start_time.to_time
    e = end_time.is_a?(String)   ? Time.iso8601(end_time)   : end_time.to_time

    Reservation.where(
      user_id: user_id,
      item_id: item_id,
      in_cart: true
    ).where(
      # overlap test: (hold.start < range.end) AND (hold.end > range.start)
      "start_time < ? AND end_time > ?",
      e, s
    ).delete_all
  rescue => e
    Rails.logger.warn("Hold release failed: #{e.class}: #{e.message}")
  end


  def require_login!
    redirect_to root_path, alert: "Please sign in first." unless current_user
  end

  def permit_entry(src)
    p = src.is_a?(ActionController::Parameters) ? src : ActionController::Parameters.new(src)
    p.permit(:item_id, :workspace_id, :start_time, :end_time, :quantity).to_h
  end
end
