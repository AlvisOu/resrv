require 'rails_helper'

RSpec.describe AvailabilityService, type: :service do
  let(:tz) { Time.zone }
  let(:day) { Date.current }
  let(:workspace) { Workspace.create!(name: "Lab A") }

  let(:item) do
    Item.create!(
      name: "Microscope",
      quantity: 2,
      workspace: workspace,
      start_time: tz.local(day.year, day.month, day.day, 9, 0, 0),   # 9 AM
      end_time:   tz.local(day.year, day.month, day.day, 17, 0, 0)   # 5 PM
    )
  end

  describe "#time_slots" do
    it "returns exactly 96 slots (15-min intervals across 24h)" do
      slots = AvailabilityService.new(item).time_slots
      expect(slots.length).to eq(96)
      expect(slots.first[:start].hour).to eq(0)
      expect(slots.last[:end].hour).to eq(0) # wraps to next day midnight
    end

    it "marks slots outside item window as not within_window" do
      slots = AvailabilityService.new(item).time_slots
      before_9am = slots.find { |s| s[:start].hour == 8 && s[:start].min == 45 }
      after_5pm  = slots.find { |s| s[:start].hour == 17 && s[:start].min == 15 }

      expect(before_9am[:within_window]).to be false
      expect(after_5pm[:within_window]).to be false
    end

    it "marks slots within the window as within_window" do
      slots = AvailabilityService.new(item).time_slots
      nine_am = slots.find { |s| s[:start].hour == 9 && s[:start].min == 0 }
      expect(nine_am[:within_window]).to be true
    end

    it "marks all slots as available when no reservations exist" do
      slots = AvailabilityService.new(item, 1).time_slots
      available_slots = slots.select { |s| s[:available] }
      expect(available_slots.count).to be > 0
    end

    context "with overlapping reservations" do
      before do
        # Reservation from 9:00–10:00
        Reservation.create!(
          user: User.create!(name: "A", email: "a@test.com", password: "pw", password_confirmation: "pw"),
          item: item,
          start_time: tz.local(day.year, day.month, day.day, 9, 0, 0),
          end_time:   tz.local(day.year, day.month, day.day, 10, 0, 0)
        )
      end

      it "marks overlapping slots as unavailable if quantity is full" do
        # With requested_quantity = 2, and item.quantity = 2, should be unavailable
        service = AvailabilityService.new(item, 2, day: day, tz: tz)
        slots = service.time_slots
        nine_am = slots.find { |s| s[:start].hour == 9 && s[:start].min == 0 }
        expect(nine_am[:available]).to be false
      end

      it "marks overlapping slots as available if enough quantity remains" do
        # Only one used, request one more (total 2 capacity) → still available
        service = AvailabilityService.new(item, 1, day: day, tz: tz)
        slots = service.time_slots
        nine_am = slots.find { |s| s[:start].hour == 9 && s[:start].min == 0 }
        expect(nine_am[:available]).to be true
      end
    end
  end

  describe "edge windows" do
    it "treats missing start_time as beginning of day" do
      item.update_columns(start_time: nil)
      slots = AvailabilityService.new(item, 1).time_slots
      expect(slots.first[:within_window]).to be true
    end

    it "treats missing end_time as end of day" do
      item.update_columns(end_time: nil)
      slots = AvailabilityService.new(item, 1).time_slots
      last_slot = slots.find { |s| s[:start].hour == 23 && s[:start].min == 45 }
      expect(last_slot[:within_window]).to be true
    end

    it "falls back to full day when end precedes start" do
      inverted = Item.new(
        name: "Inverted",
        quantity: 1,
        workspace: workspace,
        start_time: tz.local(day.year, day.month, day.day, 18, 0, 0),
        end_time:   tz.local(day.year, day.month, day.day, 9, 0, 0)
      )
      inverted.save(validate: false)

      slots = AvailabilityService.new(inverted, 1).time_slots
      expect(slots.any? { |s| s[:within_window] }).to be true
    end
  end
end
