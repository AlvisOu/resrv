# lib/tasks/reservations.rake

namespace :reservations do
  desc "Find unreturned reservations and adjust item stock"
  task process_unreturned: :environment do
    
    puts "Running unreturned reservation processor..."
    
    # Define the cutoff time (30 minutes ago)
    # Note: We do not process items 5-30 mins late here because we don't want to 
    # deduct stock for minor lateness. Those are handled upon return in the controller.
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
          # Create Missing Report
          MissingReport.create!(
            reservation: reservation,
            item: item,
            workspace: item.workspace,
            quantity: still_missing,
            resolved: false,
            status: 'pending',
            reported_at: Time.current
          )

          # Create Penalty for late return (> 30 mins)
          Penalty.create!(
            user: reservation.user,
            reservation: reservation,
            workspace: item.workspace,
            reason: "late_return",
            expires_at: 2.weeks.from_now
          )

          # Deduct the missing stock from the item
          new_item_quantity = [0, item.quantity - still_missing].max
          item.update!(quantity: new_item_quantity)

          # Mark this reservation as "processed" so we never touch it again
          reservation.update_columns(stock_adjusted: true)
        end
        puts "  -> Success: Item ID #{item.id} quantity is now #{item.quantity}."
      rescue => e
        puts "  -> FAILED processing Reservation ##{reservation.id}: #{e.message}"
      end
    end
    
    puts "Done."
  end
end