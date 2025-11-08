class ReservationsController < ApplicationController
    before_action :require_user
    before_action :set_reservation_and_workspace, only: [:mark_no_show, :mark_not_returned]

    def availability
        item = Item.friendly.find(params[:item_id])
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

    def mark_no_show
        unless current_user_is_owner?(@workspace)
            redirect_to @workspace, alert: "Not authorized."
        end
        new_status = !@reservation.no_show
        @reservation.update(no_show: new_status)
        notice = new_status ? 
            "#{@reservation.user.name} marked as no-show." : 
            "No-show status reverted for #{@reservation.user.name}."
            
        redirect_to @workspace, notice: notice
    end

    def mark_not_returned
        unless current_user_is_owner?(@workspace)
            redirect_to @workspace, alert: "Not authorized."
        end
        new_status = !@reservation.not_returned
        @reservation.update(not_returned: new_status)
        notice = new_status ?
            "#{@reservation.user.name} marked as not returned." :
            "Not returned status reverted for #{@reservation.user.name}."

        redirect_to @workspace, notice: notice
    end

    private

    def set_reservation_and_workspace
        @reservation = Reservation.find(params[:id])
        @workspace = @reservation.item.workspace
    end
end
