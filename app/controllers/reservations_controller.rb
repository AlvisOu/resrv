class ReservationsController < ApplicationController
    before_action :require_user
    before_action :set_reservation_and_workspace, only: [:mark_no_show, :return_items, :undo_return_items]

    def availability
        item = Item.find(params[:item_id])
        qty  = params[:quantity].to_i
        tz   = Time.zone || ActiveSupport::TimeZone["UTC"]

        # Parse day (YYYY-MM-DD), clamp to [today, today+7]
        today = tz.today
        max_day = today + 7.days
        day = begin
            Date.iso8601(params[:day]) if params[:day].present?
        rescue ArgumentError
            nil
        end
        day ||= today
        day = today  if day < today
        day = max_day if day > max_day

        # Window: grey out past for today; hard-stop after 7 days
        day_start = tz.local(day.year, day.month, day.day, 0, 0, 0)
        now = tz.now
        window_start = [day_start, now].max
        window_end   = (today + 7.days).in_time_zone(tz).end_of_day

        slots = AvailabilityService.new(
            item, qty,
            day: day, tz: tz,
            window_start: window_start,
            window_end: window_end
        ).time_slots

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
            return redirect_to @workspace, alert: "Not authorized."
        end

        new_status = !@reservation.no_show
        @reservation.update(no_show: new_status)

        if new_status
            Penalty.create!(
            user: @reservation.user,
            reservation: @reservation,
            workspace: @reservation.item.workspace,
            reason: "no_show",
            expires_at: 5.days.from_now
            )
        else
            penalty = Penalty.find_by(reservation: @reservation, reason: "no_show")
            penalty.destroy if penalty.present?
        end

        notice = new_status ? 
            "#{@reservation.user.name} marked as no-show." : 
            "No-show status reverted for #{@reservation.user.name}."

        redirect_to @workspace, notice: notice
    end

    def return_items
        unless current_user_is_owner?(@workspace)
            return redirect_to @workspace, alert: "Not authorized."
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

                    if lateness > 5.minutes
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
            return redirect_to @workspace, notice: "#{quantity_to_return} #{item.name}(s) returned successfully."
        rescue => e
            return redirect_to @workspace, alert: "Failed to update status: #{e.message}"
        end
    end

    def undo_return_items
        unless current_user_is_owner?(@workspace)
            return redirect_to @workspace, alert: "Not authorized."
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
            return redirect_to @workspace, notice: "Undo return of #{quantity_to_undo} #{item.name}(s) successful."
        rescue => e
            return redirect_to @workspace, alert: "Failed to update status: #{e.message}"
        end
    end


    private

    def set_reservation_and_workspace
        @reservation = Reservation.find(params[:id])
        @workspace = @reservation.item.workspace
    end

    def ceil_to_15(time)
        remainder = (time.min % 15)
        return time.change(sec: 0) if remainder.zero? && time.sec.zero?
        time.change(sec: 0) + (15 - remainder).minutes
    end
end
