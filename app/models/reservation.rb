class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :item
  has_many :penalties,     dependent: :delete_all   # or :destroy if you need callbacks
  has_many :notifications, dependent: :delete_all   # add this association if not present
  has_one :missing_report, dependent: :destroy

  validates :start_time, :end_time, presence: true

  include TimeValidatable
  validate :end_time_after_start_time
  validate :check_availability

  def auto_mark_missing_items
    return unless item.present?

    actual_returned = returned_count.to_i
    booked = quantity.to_i

    return unless Time.current > (end_time + 29.minutes + 59.seconds)

    missing_qty = booked - actual_returned
    return unless missing_qty.positive?

    return if MissingReport.exists?(reservation: self, item: item, workspace: item.workspace)

    MissingReport.create!(
      reservation: self,
      item: item,
      workspace: item.workspace,
      quantity: missing_qty,
      resolved: false
    )

    item.decrement!(:quantity, missing_qty)
  end

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
