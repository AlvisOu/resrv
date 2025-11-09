class CheckoutService
  attr_reader :cart, :user, :workspace_id, :errors

  def initialize(cart, user, workspace_id)
    @cart = cart
    @user = user
    @workspace_id = workspace_id
    @errors = []
  end

  def call
    groups = cart.merged_segments_by_workspace
    workspace = groups.keys.compact.find { |w| w.id == workspace_id }
    segments  = groups[workspace] || []

    if segments.blank?
      add_error("No items in cart for this workspace.")
      return false
    end
    run_checkout(segments)
  end

  private

  def run_checkout(segments)
    ActiveRecord::Base.transaction do
      segments.each do |seq|
        unless process_segment(seq)
          raise ActiveRecord::Rollback
        end
      end

      cart.clear_workspace!(workspace_id)
    end

    @errors.empty?
  end

  def process_segment(seg)
    item = seg[:item]
    s    = seg[:start_time]
    e    = seg[:end_time]
    q    = seg[:quantity].to_i

    return add_error("Item no longer exists.") if item.nil?
    return add_error("Invalid time/quantity for #{item.name}.") if s.blank? || e.blank? || s >= e || q <= 0

    if user.blocked_from_reserving_in?(item.workspace)
      return add_error("You are blocked from making reservations in #{item.workspace.name} due to a recent penalty.")
    end

    unless capacity_available?(item, s, e, q)
      return add_error("Not enough capacity for #{item.name} between #{s.in_time_zone.strftime('%-I:%M %p')}–#{e.in_time_zone.strftime('%-I:%M %p')}.")
    end

    reservation = Reservation.create!(
      user_id:    user.id,
      item_id:    item.id,
      start_time: s,
      end_time:   e,
      quantity:   q
    )

    Notification.create!(
      user: user,
      reservation: reservation,
      message: "You reserved #{reservation.quantity}x #{item.name} in #{item.workspace.name} from #{s.strftime('%-I:%M %p')} to #{e.strftime('%-I:%M %p')}.",
      read: false
    )

    ReservationReminderJob.set(wait_until: reservation.start_time - 2.hours).perform_later(reservation.id, 'start')
    ReservationReminderJob.set(wait_until: reservation.end_time - 10.minutes).perform_later(reservation.id, 'end')

    true
  end

  def capacity_available?(item, start_time, end_time, quantity)
    existing = Reservation.
      where(item_id: item.id).
      where("start_time < ? AND end_time > ?", end_time, start_time).
      sum(:quantity)

    (existing + quantity) <= item.quantity.to_i
  end

  def add_error(message)
    @errors << message
    false
  end
end