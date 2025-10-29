class ReservationsController < ApplicationController
    before_action :require_user

    def availability
        item = Item.find(params[:item_id])
        quantity = params[:quantity].to_i.clamp(0, item.quantity.to_i)
        day = Date.current
        tz  = Time.zone

        slots = AvailabilityService.new(item, quantity, day: day, tz: tz).time_slots
        render json: { slots: slots }
    end

    def index
        # Group reservations by identical (start, end, item)
        @reservations = current_user.reservations
                                    .includes(item: :workspace)
                                    .group_by { |r| [r.start_time, r.end_time, r.item_id] }
    end

    def destroy
        reservation = current_user.reservations.find(params[:id])
        reservation.destroy
        flash[:notice] = "Reservation canceled successfully."
        redirect_to reservations_path
    end
end
