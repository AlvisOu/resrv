class ReservationsController < ApplicationController
    before_action :require_user
    before_action :set_reservation_and_workspace, only: [:mark_no_show, :return_items, :undo_return_items, :show, :owner_cancel]
    before_action :authorize_owner!, only: [:show, :owner_cancel]

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

    def show
    end

    def index
        # Group reservations by identical (start, end, item)
    @reservations = current_user.reservations
                                .checked_out
                                .includes(item: :workspace)
                                .order(start_time: :asc)
    end

    def destroy
        reservation = current_user.reservations.find(params[:id])

        if reservation.start_time <= Time.current
            flash[:alert] = "You cannot cancel a reservation that has already started."
            return redirect_to reservations_path
        end

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
        if quantity_to_return < 0
            return redirect_to @workspace, alert: "Please enter a valid number (0 or more)."
        end

        total_reserved = @reservation.quantity
        current_returned = @reservation.returned_count
        max_possible_return = total_reserved - current_returned

        if quantity_to_return > max_possible_return
            return redirect_to @workspace, alert: "Cannot return more than reserved. Max possible to return: #{max_possible_return}."
        end

        begin
            missing_report_created = false
            ActiveRecord::Base.transaction do
                @reservation.update!(returned_count: current_returned + quantity_to_return)
                
                # If nothing was returned, create a missing report right away
                if quantity_to_return == 0
                    missing_qty = total_reserved - current_returned
                    if missing_qty > 0 && !MissingReport.exists?(reservation: @reservation, item: item, workspace: @workspace)
                        MissingReport.create!(
                            reservation: @reservation,
                            item: item,
                            workspace: @workspace,
                            quantity: missing_qty,
                            resolved: false
                        )
                        item.decrement!(:quantity, missing_qty)
                        missing_report_created = true
                    end
                end
                
                if @reservation.end_time < Time.current && quantity_to_return > 0
                    lateness = Time.current - @reservation.end_time

                    if lateness > 5.minutes && !Penalty.exists?(reservation: @reservation, reason: "late_return")
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
            
            if quantity_to_return == 0
                message = if missing_report_created
                  "Marked as nothing returned. Missing report created."
                else
                  "Marked as nothing returned."
                end
                return redirect_to @workspace, notice: message
            else
                return redirect_to @workspace, notice: "#{quantity_to_return} #{item.name}(s) returned successfully."
            end
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
                new_returned = current_returned - quantity_to_undo
                @reservation.update!(returned_count: new_returned)
                
                # If undoing would result in missing items and a missing report exists, delete it and restore quantity
                total_reserved = @reservation.quantity
                if new_returned < total_reserved
                    missing_report = MissingReport.find_by(reservation: @reservation, item: item, workspace: @workspace, resolved: false)
                    if missing_report
                        # Restore item quantity
                        item.increment!(:quantity, missing_report.quantity)
                        # Delete the missing report
                        missing_report.destroy!
                    end
                end
                
                # Remove late_return penalty if it exists and was created for this reservation
                if @reservation.end_time < Time.current
                    late_penalty = Penalty.find_by(reservation: @reservation, reason: "late_return")
                    late_penalty&.destroy
                end
            end
            return redirect_to @workspace, notice: "Undo return of #{quantity_to_undo} #{item.name}(s) successful."
        rescue => e
            return redirect_to @workspace, alert: "Failed to update status: #{e.message}"
        end
    end

    def owner_cancel
        Reservation.transaction do
            user = @reservation.user
            workspace = @reservation.item.workspace
            @reservation.destroy!
            Notification.create!(
                user: user,
                reservation: nil,
                message: "Your reservation in #{workspace.name} was canceled by the workspace owner."
            )
        end
        redirect_to @workspace, notice: "Reservation canceled and user notified."
    rescue => e
        redirect_to @workspace, alert: "Failed to cancel reservation: #{e.message}"
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

    def authorize_owner!
        return if current_user_is_owner?(@workspace)

        redirect_to @workspace, alert: "Not authorized."
    end
end
