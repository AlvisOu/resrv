class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :item

  validates :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validate :check_availability

  private
  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after the start time")
    end
  end

  def check_availability
    return if item.blank? || start_time.blank? || end_time.blank?

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

    # Overlap check
  end
end
