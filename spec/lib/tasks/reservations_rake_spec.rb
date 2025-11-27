require 'rails_helper'
require 'rake'

RSpec.describe "reservations:process_unreturned" do
  before :all do
    Rake.application.rake_require "tasks/reservations"
    Rake::Task.define_task(:environment)
  end

  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "pw") }
  let!(:workspace) { Workspace.create!(name: "Lab") }
  
  # Setup times
  let(:now) { Time.zone.now }
  let(:past_start) { now - 2.hours }
  let(:past_end)   { now - 1.hour } # Ended 1 hour ago (> 30 mins)

  # Item with Quantity 2
  let!(:item) { 
    Item.create!(
      name: "Projector", 
      quantity: 2, 
      workspace: workspace, 
      start_time: now.beginning_of_day, 
      end_time: now.end_of_day
    ) 
  }

  # Reservation A: Unreturned (Qty 1)
  let!(:res_unreturned) {
    Reservation.create!(
      user: user, item: item, 
      start_time: past_start, end_time: past_end, 
      quantity: 1, returned_count: 0, stock_adjusted: false
    )
  }

  # Reservation B: Overlapping (Qty 1) - This consumes the rest of the capacity
  let!(:res_overlapping) {
    Reservation.create!(
      user: user, item: item, 
      start_time: past_start, end_time: past_end, 
      quantity: 1, returned_count: 1 # Returned or not doesn't matter for overlap check
    )
  }

  it "successfully processes unreturned reservations even when capacity is tight" do
    # Initial state check
    expect(item.quantity).to eq(2)
    expect(res_unreturned.stock_adjusted).to be false

    # Run the rake task
    output = capture_stdout { Rake::Task["reservations:process_unreturned"].invoke }

    # Reload to check changes
    item.reload
    res_unreturned.reload

    # Expect item quantity to be reduced by 1 (because Res A is missing 1)
    expect(item.quantity).to eq(1)
    
    # Expect reservation to be marked as processed
    expect(res_unreturned.stock_adjusted).to be true
    
    # Verify output contains success message
    expect(output).to include("Success: Item ID #{item.id} quantity is now 1")
    expect(output).not_to include("FAILED processing")
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
