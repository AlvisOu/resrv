class ReservationsController < ApplicationController
  def availability
    item = Item.find(params[:item_id])
    quantity = params[:quantity].to_i

    slots = AvailabilityService.new(item, quantity).time_slots

    render json: { slots: slots }
  end
end
