class AvailabilityService
  SLOT_INTERVAL = 15.minutes

  # window_start/window_end are optional and let the caller grey out past-today or >7d
  def initialize(item, requested_quantity = 1, day: Date.current, tz: Time.zone, window_start: nil, window_end: nil)
    @item = item
    @requested_quantity = requested_quantity.to_i
    @day = day
    @tz  = tz || ActiveSupport::TimeZone["UTC"]
    @window_start = window_start
    @window_end   = window_end
  end

  # Returns exactly 96 slots for the day (00:00 → 24:00)
  # { start:, end:, available:, within_window: }
  def time_slots
    day_start = @tz.local(@day.year, @day.month, @day.day, 0, 0, 0)
    day_end   = day_start + 24.hours

    # 1) Item's daily window, aligned to @day
    item_start, item_end = item_window_for_day(day_start, day_end)

    # 2) Booking window (optional)
    bw_start = @window_start || day_start
    bw_end   = @window_end   || day_end

    # 3) Effective window = intersection of (day) ∩ (item window) ∩ (booking window)
    effective_start = [day_start, item_start, bw_start].max
    effective_end   = [day_end,   item_end,   bw_end].min

    slots = []
    t = day_start
    while t < day_end
      slot_end = t + SLOT_INTERVAL

      # within_window means the whole 15-min slot is inside the effective window
      within_window = (t >= effective_start) && (slot_end <= effective_end)

      available = false
      if within_window
        overlapping = @item.reservations
                          .active_for_capacity
                          .where("(start_time < ?) AND (end_time > ?)", slot_end, t)
        used_quantity = overlapping.sum(:quantity)
        total_quantity = @item.quantity.to_i
        available = (used_quantity + @requested_quantity) <= total_quantity
      end

      slots << { start: t, end: slot_end, available: available, within_window: within_window }
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
