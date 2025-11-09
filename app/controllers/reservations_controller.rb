class ReservationsController < ApplicationController
    before_action :require_user
    before_action :set_reservation_and_workspace, only: [:mark_no_show, :return_items, :undo_return_items]

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
                                    .order(start_time: :asc)
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

        if new_status
            Penalty.create!(
            user: @reservation.user,
            reservation: @reservation,
            workspace: @reservation.item.workspace,
            reason: :no_show,
            expires_at: 2.weeks.from_now
            )
        else
            @reservation.penalty&.destroy
        end

        notice = new_status ? 
            "#{@reservation.user.name} marked as no-show." : 
            "No-show status reverted for #{@reservation.user.name}."
            
        redirect_to @workspace, notice: notice
    end

    def return_items
        unless current_user_is_owner?(@workspace)
            redirect_to @workspace, alert: "Not authorized."
        end
        item = @reservation.item
        quantity_to_return = params[:quantity_to_return].to_i
        if quantity_to_return <= 0
            return redirect_to @workspace, alert: "Please enter a positive number."
        end

        total_reserved = @reservation.quantity
        current_returned = @reservation.returned_count
        max_possible_return = total_reserved - current_returned

        if quantity_to_return > max_possible_return
            return redirect_to @workspace, alert: "Cannot return more than reserved. Max possible to return: #{max_possible_return}."
        end

        begin
            ActiveRecord::Base.transaction do
                @reservation.update!(returned_count: current_returned + quantity_to_return)
                if @reservation.end_time < Time.current
                    lateness = Time.current - @reservation.end_time

                    if lateness > 15.minutes
                    duration = lateness > 30.minutes ? 2.weeks : 2.days
                    Penalty.create!(
                        user: @reservation.user,
                        reservation: @reservation,
                        workspace: @reservation.item.workspace,
                        reason: :late_return,
                        expires_at: duration.from_now
                    )
                    end
                end
            end
            redirect_to @workspace, notice: "#{quantity_to_return} #{item.name}(s) returned successfully."
        rescue => e
            redirect_to @workspace, alert: "Failed to update status: #{e.message}"
        end
    end

    def undo_return_items
        unless current_user_is_owner?(@workspace)
            redirect_to @workspace, alert: "Not authorized."
        end
        item = @reservation.item
        quantity_to_undo = params[:quantity_to_undo].to_i
        if quantity_to_undo <= 0
            return redirect_to @workspace, alert: "Please enter a positive number."
        end

        current_returned = @reservation.returned_count
        if quantity_to_undo > current_returned
            return redirect_to @workspace, alert: "Cannot undo more than returned. Currently returned: #{current_returned}."
        end

        begin
            ActiveRecord::Base.transaction do
                @reservation.update!(returned_count: current_returned - quantity_to_undo)
            end
            redirect_to @workspace, notice: "Undo return of #{quantity_to_undo} #{item.name}(s) successful."
        rescue => e
            redirect_to @workspace, alert: "Failed to update status: #{e.message}"
        end
    end

    private

    def set_reservation_and_workspace
        @reservation = Reservation.find(params[:id])
        @workspace = @reservation.item.workspace
    end
end
