class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :item
  has_many :penalties,     dependent: :delete_all
  has_many :notifications, dependent: :delete_all
  has_one  :missing_report, dependent: :destroy

  validates :start_time, :end_time, presence: true

  include TimeValidatable
  validate :end_time_after_start_time
  validate :check_availability

  # ==== Scopes ====

  # Real, checked-out reservations (not in-cart holds)
  scope :checked_out, -> { where(in_cart: false) }

  # For capacity math: count real reservations + active holds, ignore expired holds
  scope :active_for_capacity, -> {
    where("(in_cart = FALSE) OR (in_cart = TRUE AND hold_expires_at IS NOT NULL AND hold_expires_at > ?)", Time.zone.now)
  }

  def self.notify_and_purge_expired_holds!
    now = Time.zone.now

    expired = where("in_cart = TRUE AND hold_expires_at IS NOT NULL AND hold_expires_at <= ?", Time.zone.now)
          .includes(:user, item: :workspace)

    expired.find_each do |hold|
      item      = hold.item
      workspace = item&.workspace
      user      = hold.user

      msg =
        if item && workspace
          "Your hold on #{item.name} (#{workspace.name}) from " \
          "#{hold.start_time.in_time_zone.strftime('%-I:%M %p')} to " \
          "#{hold.end_time.in_time_zone.strftime('%-I:%M %p')} expired and was removed from your cart."
        else
          "One of your held reservations expired and was removed from your cart."
        end

      Notification.create!(
        user: user,
        reservation_id: nil,
        message: msg,
        read: false
      )
    end

    where(id: expired.select(:id)).delete_all
  end

  # ==== Existing logic ====

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

    # If items can be open-ended, skip window checks
    return if item.start_time.blank? || item.end_time.blank?

    # Extract only the time-of-day
    reservation_start = start_time.seconds_since_midnight
    reservation_end   = end_time.seconds_since_midnight
    item_start        = item.start_time.seconds_since_midnight
    item_end          = item.end_time.seconds_since_midnight

    if reservation_start < item_start
      errors.add(:start_time, "is before the item's daily availability window")
    end

    if reservation_end > item_end
      errors.add(:end_time, "is after the item's daily availability window")
    end
  end

  def validate_no_time_overlap
    return if item.nil? || start_time.blank? || end_time.blank?

    overlapping = item.reservations
                      .merge(Reservation.active_for_capacity)
                      .where.not(id: self.id)
                      .where("(start_time < :new_end AND end_time > :new_start)",
                             new_end: self.end_time, new_start: self.start_time)

    used = overlapping.sum(:quantity)
    if used >= item.quantity
      errors.add(:base, "This item is fully booked for the selected time period")
    end
  end
end
