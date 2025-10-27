class ReservationsController < ApplicationController
  def availability
    item = Item.find(params[:item_id])
    quantity = params[:quantity].to_i.clamp(0, item.quantity.to_i)
    day = Date.current
    tz  = Time.zone

    slots = AvailabilityService.new(item, quantity, day: day, tz: tz).time_slots
    render json: { slots: slots }
  end
end
