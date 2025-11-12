class PurgeExpiredHoldsJob < ApplicationJob
  queue_as :default

  def perform
    Reservation.notify_and_purge_expired_holds!
  end
end
