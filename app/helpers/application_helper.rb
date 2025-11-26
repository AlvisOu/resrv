module ApplicationHelper
  def cart_display
    return "Cart" unless current_user

    cart  = Cart.load(session, current_user.id)
    count = cart.reservations_count  # 👈 use segments count, not quantity sum

    if count.positive?
      "Cart (#{count})"
    else
      "Cart"
    end
  end
end
