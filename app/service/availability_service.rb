class AvailabilityService
  SLOT_INTERVAL = 15.minutes

  def initialize(item, requested_quantity = 1, day: Date.current, tz: Time.zone, window_start: nil, window_end: nil)
    @item = item
    @requested_quantity = requested_quantity.to_i
    @day = day
    @tz  = tz || ActiveSupport::TimeZone["UTC"]
    @window_start = window_start
    @window_end   = window_end
  end

  def time_slots
    day_start = @tz.local(@day.year, @day.month, @day.day, 0, 0, 0)
    day_end   = day_start + 24.hours

    item_start, item_end = item_window_for_day(day_start, day_end)

    bw_start = @window_start || day_start
    bw_end   = @window_end   || day_end

    effective_start = [day_start, item_start, bw_start].max
    effective_end   = [day_end,   item_end,   bw_end].min

    total_quantity = @item.quantity.to_i

    slots = []
    t = day_start
    while t < day_end
      slot_end = t + SLOT_INTERVAL

      within_window = (t >= effective_start) && (slot_end <= effective_end)

      used_quantity = 0
      available = false

      if within_window
        overlapping = @item.reservations
                           .active_for_capacity
                           .where("(start_time < ?) AND (end_time > ?)", slot_end, t)
        used_quantity = overlapping.sum(:quantity)
        available = (used_quantity + @requested_quantity) <= total_quantity
      end

      slots << {
        start:          t,
        end:            slot_end,
        available:      available,
        within_window:  within_window,
        used_quantity:  used_quantity,
        total_quantity: total_quantity
      }

      t = slot_end
    end

    slots
  end
  
  private

  # Safely derive the item window for @day; if either bound is nil, treat as open
  def item_window_for_day(day_start, day_end)
    if @item.start_time.present?
      s = align_to_day(@item.start_time)
    else
      s = day_start
    end

    if @item.end_time.present?
      e = align_to_day(@item.end_time)
    else
      e = day_end
    end

    # If someone inverted start/end, normalize to full-day to avoid “all grey”
    if e <= s
      [day_start, day_end]
    else
      [s, e]
    end
  end

  # Ensure consistent slot alignment for the given @day
  def align_to_day(time)
    time.in_time_zone(@tz).change(year: @day.year, month: @day.month, day: @day.day)
  end
end
