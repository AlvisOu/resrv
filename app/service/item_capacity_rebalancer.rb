class ItemCapacityRebalancer
  SLOT = AvailabilityService::SLOT_INTERVAL rescue 15.minutes

  def self.rebalance!(item, tz: Time.zone)
    new(item, tz: tz || Time.zone).rebalance!
  end

  def initialize(item, tz:)
    @item = item
    @tz   = tz || Time.zone
  end

  def rebalance!
    total = @item.quantity.to_i
    return if total <= 0

    now = @tz.now

    # Only reservations that still count against capacity in the future
    scope = @item.reservations
                 .active_for_capacity
                 .where("end_time > ?", now)

    reservations = scope.order(:created_at, :id).to_a
    return if reservations.empty?

    # used[timestamp_integer] => quantity used in that 15min tick
    used = Hash.new(0)
    to_cancel = []

    reservations.each do |res|
      if fits?(res, used, total)
        mark_used!(res, used)
      else
        to_cancel << res
      end
    end

    return if to_cancel.empty?

    Reservation.transaction do
      to_cancel.each do |res|
        user      = res.user
        workspace = @item.workspace

        # Optional: notify the user what happened
        begin
          Notification.create!(
            user:        user,
            reservation: nil,
            message:     cancel_message(res, workspace)
          )
        rescue => e
          Rails.logger.warn("ItemCapacityRebalancer notification failed: #{e.class}: #{e.message}")
        end

        res.destroy!
      end
    end
  end

  private

  def fits?(res, used, total)
    each_slot(res) do |t|
      return false if used[t.to_i] + res.quantity.to_i > total
    end
    true
  end

  def mark_used!(res, used)
    each_slot(res) do |t|
      used[t.to_i] += res.quantity.to_i
    end
  end

  def each_slot(res)
    s = res.start_time.in_time_zone(@tz)
    e = res.end_time.in_time_zone(@tz)

    t = floor_to_slot(s)
    while t < e
      yield t
      t += SLOT
    end
  end

  def floor_to_slot(time)
    time = time.in_time_zone(@tz).change(sec: 0)
    time - (time.min % 15).minutes
  end

  def cancel_message(res, workspace)
    time_str = res.start_time
                 .in_time_zone(@tz)
                 .strftime("%b %-d, %Y %-I:%M %p")

    "Your reservation for #{res.item.name} on #{time_str} " \
    "in #{workspace.name} was canceled because fewer copies " \
    "of this item are now available."
  end
end
