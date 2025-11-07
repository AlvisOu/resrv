class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :item

  validates :start_time, :end_time, presence: true

  include TimeValidatable
  validate :end_time_after_start_time
  validate :check_availability

  private

  def check_availability
    validate_time_within_item_window
    validate_no_time_overlap
  end

  def validate_time_within_item_window
    return if item.nil? || start_time.blank? || end_time.blank?

    # Extract only the time-of-day
    reservation_start = start_time.seconds_since_midnight
    reservation_end   = end_time.seconds_since_midnight
    item_start        = item.start_time.seconds_since_midnight
    item_end          = item.end_time.seconds_since_midnight

    # Eligibility check
    if reservation_start < item_start
      errors.add(:start_time, "is before the item's daily availability window")
    end

    if reservation_end > item_end
      errors.add(:end_time, "is after the item's daily availability window")
    end
  end

  def validate_no_time_overlap
    overlapping_reservations = item.reservations.where.not(id: self.id).where(
      "(start_time < :new_end_time AND end_time > :new_start_time) OR (start_time < :new_start_time AND end_time > :new_end_time)",
      new_end_time: self.end_time, new_start_time: self.start_time
    )

    if overlapping_reservations.count >= item.quantity
      errors.add(:base, "This item is fully booked for the selected time period")
    end
  end
end
