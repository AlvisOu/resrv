class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation_id, reminder_type)
    reservation = Reservation.find_by(id: reservation_id)
    return unless reservation && reservation.user

    item = reservation.item
    return unless item && item.workspace

    message =
      case reminder_type
      when 'start'
        "Reminder: your reservation for #{reservation.quantity}x #{item.name} in #{item.workspace.name} starts in 2 hours!"
      when 'end'
        "Reminder: your reservation for #{reservation.quantity}x #{item.name} in #{item.workspace.name} ends in 10 minutes!"
      else
        "Reminder about your reservation for #{reservation.quantity}x #{item.name} in #{item.workspace.name}."
      end

    Notification.create!(
      user: reservation.user,
      reservation: reservation,
      message: message,
      read: false
    )
  end
end