# lib/tasks/reservations.rake

namespace :reservations do
  desc "Find unreturned reservations and adjust item stock"
  task process_unreturned: :environment do
    
    puts "Running unreturned reservation processor..."
    
    # Define the cutoff time (30 minutes ago)
    cutoff_time = 30.minutes.ago

    # Find all reservations that:
    #  - Ended more than 30 minutes ago
    #  - Have NOT been processed yet (stock_adjusted is false)
    #  - Are still "missing" items (returned < total)
    reservations_to_process = Reservation
      .where("end_time < ?", cutoff_time)
      .where(stock_adjusted: false)
      .where("returned_count < quantity")
      .includes(:item)

    puts "Found #{reservations_to_process.count} reservations to process."

    # Loop through each one and process it
    reservations_to_process.each do |reservation|
      item = reservation.item
      still_missing = reservation.quantity - reservation.returned_count

      puts "  Processing Reservation ##{reservation.id}: #{still_missing} '#{item.name}' missing."
      
      begin
        ActiveRecord::Base.transaction do
          # Deduct the missing stock from the item
          new_item_quantity = [0, item.quantity - still_missing].max
          item.update!(quantity: new_item_quantity)

          # Mark this reservation as "processed" so we never touch it again
          reservation.update!(stock_adjusted: true)
        end
        puts "  -> Success: Item ID #{item.id} quantity is now #{item.quantity}."
      rescue => e
        puts "  -> FAILED processing Reservation ##{reservation.id}: #{e.message}"
      end
    end
    
    puts "Done."
  end
end