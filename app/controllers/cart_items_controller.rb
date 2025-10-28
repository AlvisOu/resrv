class CartItemsController < ApplicationController
  skip_forgery_protection
  before_action :require_login!

  def create
    cart = Cart.load(session, current_user.id)
    raw = params[:selections] || params.dig(:cart_item, :selections) || []
    raw = JSON.parse(raw) if raw.is_a?(String)
    Array(raw).each { |attrs| cart.add!(permit_entry(attrs)) }
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

  # remove_range stays the same but uses current_user.id
  def remove_range
    cart = Cart.load(session, current_user.id)
    cart.remove_range!(
      item_id: params[:item_id],
      workspace_id: params[:workspace_id],
      start_time: params[:start_time],
      end_time: params[:end_time]
    )
    respond_to do |format|
      format.html { redirect_to cart_path(workspace_id: params[:workspace_id]), notice: "Removed from cart." }
      format.json { render json: { ok: true, total: cart.total_count } }
    end
  end

  private
  def require_login!
    redirect_to root_path, alert: "Please sign in first." unless current_user
  end

  def permit_entry(src)
    p = src.is_a?(ActionController::Parameters) ? src : ActionController::Parameters.new(src)
    p.permit(:item_id, :workspace_id, :start_time, :end_time, :quantity).to_h
  end
end
