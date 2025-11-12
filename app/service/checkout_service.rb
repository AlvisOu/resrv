class CheckoutService
  SLOT = 15.minutes
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

    # Try converting user's holds first. If that succeeds, we’re done.
    if (reservation = convert_user_holds!(item, s, e, q))
      enqueue_notifications!(reservation)
      return true
    end

    # Otherwise use normal capacity check, excluding this user's in-cart holds to avoid double-counting
    unless capacity_available_excluding_own_holds?(item, s, e, q)
      return add_error("Not enough capacity for #{item.name} between #{s.in_time_zone.strftime('%-I:%M %p')}–#{e.in_time_zone.strftime('%-I:%M %p')}.")
    end

    # Create fresh reservation (no holds existed or not fully covering)
    reservation = Reservation.create!(
      user_id:    user.id,
      item_id:    item.id,
      start_time: s,
      end_time:   e,
      quantity:   q,
      in_cart:    false,
      hold_expires_at: nil
    )

    enqueue_notifications!(reservation)
    true
  end

  def capacity_available_excluding_own_holds?(item, start_time, end_time, quantity)
    existing = Reservation
      .where(item_id: item.id)
      .merge(Reservation.active_for_capacity)                 # counts others’ holds + real reservations
      .where("start_time < ? AND end_time > ?", end_time, start_time)
      .where("NOT (in_cart = TRUE AND user_id = ?)", user.id) # exclude my own holds
      .sum(:quantity)

    (existing + quantity) <= item.quantity.to_i
  end

  # --- NEW: convert user's holds into one real reservation for this segment if they fully cover it ---
  def convert_user_holds!(item, seg_start, seg_end, seg_qty)
    now = Time.zone.now

    holds = Reservation.where(
      user_id: user.id,
      item_id: item.id,
      in_cart: true
    ).where("hold_expires_at > ?", now)
     .where("start_time < ? AND end_time > ?", seg_end, seg_start) # any overlap with segment

    return nil if holds.blank?

    # Build 15-min coverage map (sum of quantities) from the holds
    coverage = Hash.new(0)
    holds.find_each do |h|
      t = round_down(h.start_time)
      he = round_up(h.end_time)
      while t < he
        coverage[t.to_i] += h.quantity.to_i
        t += SLOT
      end
    end

    # Verify every tick in the segment is covered at least seg_qty
    t = round_down(seg_start)
    seg_end_ceil = round_up(seg_end)
    fully_covered = true
    while t < seg_end_ceil
      if coverage[t.to_i] < seg_qty
        fully_covered = false
        break
      end
      t += SLOT
    end

    return nil unless fully_covered

    # Convert: delete the holds, create one real reservation row for the whole segment
    Reservation.where(id: holds.select(:id)).delete_all
    Reservation.create!(
      user_id:    user.id,
      item_id:    item.id,
      start_time: seg_start,
      end_time:   seg_end,
      quantity:   seg_qty,
      in_cart:    false,
      hold_expires_at: nil
    )
  end

  def round_down(t)
    t = t.change(sec: 0)
    t - (t.min % 15).minutes
  end

  def round_up(t)
    t = t.change(sec: 0)
    rem = (15 - (t.min % 15)) % 15
    rem.zero? ? t : t + rem.minutes
  end

  def enqueue_notifications!(reservation)
    Notification.create!(
      user: user,
      reservation: reservation,
      message: "You reserved #{reservation.quantity}x #{reservation.item.name} in #{reservation.item.workspace.name} from #{reservation.start_time.strftime('%-I:%M %p')} to #{reservation.end_time.strftime('%-I:%M %p')}.",
      read: false
    )
    ReservationReminderJob.set(wait_until: reservation.start_time - 2.hours).perform_later(reservation.id, 'start')
    ReservationReminderJob.set(wait_until: reservation.end_time - 10.minutes).perform_later(reservation.id, 'end')
  end

  def capacity_available?(item, start_time, end_time, quantity)
    existing = Reservation
      .where(item_id: item.id)
      .active_for_capacity
      .where("start_time < ? AND end_time > ?", end_time, start_time)
      .sum(:quantity)

    (existing + quantity) <= item.quantity.to_i
  end

  def add_error(message)
    @errors << message
    false
  end
end