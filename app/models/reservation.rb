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

    if item.start_time.present? && start_time < item.start_time
      errors.add(:start_time, "is before the item's availability window")
    end
    if item.end_time.present? && end_time > item.end_time
      errors.add(:end_time, "is after the item's availability window")
    end

    overlapping_reservations = Reservation.where(item_id: item_id)
      .where.not(id: id)
      .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping_reservations.count >= item.quantity
      errors.add(:base, "The item is not available for the selected time period")
    end
  end
end
