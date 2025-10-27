class AvailabilityService
  SLOT_INTERVAL = 15.minutes

  def initialize(item)
    @item = item
  end

  def time_slots
    start_time = @item.start_time.change(year: Date.today.year, month: Date.today.month, day: Date.today.day)
    end_time   = @item.end_time.change(year: Date.today.year, month: Date.today.month, day: Date.today.day)

    slots = []
    while start_time < end_time
      slot_end = start_time + SLOT_INTERVAL
      overlapping_reservations = @item.reservations.where(
        "(start_time < ?) AND (end_time > ?)",
        slot_end, start_time
      )

      used_quantity = overlapping_reservations.count # extend later if reservations have quantity
      available = used_quantity < @item.quantity

      slots << { start: start_time, end: slot_end, available: available }
      start_time = slot_end
    end
    slots
  end
end
