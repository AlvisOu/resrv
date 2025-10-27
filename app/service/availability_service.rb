# frozen_string_literal: true
class AvailabilityService
  SLOT_INTERVAL = 15.minutes

  def initialize(item, requested_quantity = 1, day: Date.current, tz: Time.zone)
    @item = item
    @requested_quantity = requested_quantity.to_i
    @day = day
    @tz  = tz || ActiveSupport::TimeZone["UTC"]
  end

  # Returns exactly 96 slots for the day (00:00 → 24:00) with availability decided server-side.
  # Each element: { start:, end:, available:, within_window: }
  def time_slots
    day_start = @tz.local(@day.year, @day.month, @day.day, 0, 0, 0)
    day_end   = day_start + 24.hours

    # If item has no window, treat as full-day
    item_start = (@item.start_time ? align_to_day(@item.start_time) : day_start)
    item_end   = (@item.end_time   ? align_to_day(@item.end_time)   : day_end)

    # Guard if times are inverted/missing
    item_start, item_end = [day_start, day_end] if item_end <= item_start

    slots = []
    t = day_start
    while t < day_end
      slot_end = t + SLOT_INTERVAL

      within_window = (t >= item_start) && (t < item_end)
      available = false

      if within_window
        # NOTE: You currently don't store a per-reservation quantity.
        # This counts *reservations*, not units. See section 4 below to add quantity column.
        overlapping = @item.reservations.where("(start_time < ?) AND (end_time > ?)", slot_end, t)
        used_quantity = overlapping.count
        total_quantity = @item.quantity.to_i
        available = (used_quantity + @requested_quantity) <= total_quantity
      end

      slots << { start: t, end: slot_end, available: available, within_window: within_window }
      t = slot_end
    end

    slots
  end

  private

  def align_to_day(time)
    time.in_time_zone(@tz).change(year: @day.year, month: @day.month, day: @day.day)
  end
end
