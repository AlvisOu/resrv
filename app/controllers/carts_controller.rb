class CartsController < ApplicationController

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
    service = CheckoutService.new(@cart, current_user, workspace_id)
    if service.call
      redirect_to cart_path(workspace_id: workspace_id), notice: "Checkout complete! Your reservations have been created."
    else
      redirect_to cart_path(workspace_id: workspace_id), alert: service.errors.uniq.join(" ")
    end
  end

  private
end
