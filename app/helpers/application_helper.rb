module ApplicationHelper
  # A helper to display the cart link text
  def cart_display
    cart = Cart.load(session, current_user&.id) rescue nil
    
    if cart && cart.total_count > 0
      "Cart (#{cart.total_count})"
    else
      "Cart"
    end
  end
end
