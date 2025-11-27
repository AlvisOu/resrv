require 'rails_helper'

RSpec.describe CheckoutService, type: :service do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "pw") }
  let(:workspace) { Workspace.create!(name: "Lab") }
  let(:item) { Item.create!(name: "Microscope", quantity: 5, workspace: workspace, start_time: Time.zone.now.beginning_of_day, end_time: Time.zone.now.end_of_day) }
  let(:session) { {} }
  let(:cart) { Cart.load(session, 1) }
  let(:service) { CheckoutService.new(cart, user, workspace.id) }

  let(:now) { Time.zone.now.beginning_of_hour + 1.hour }
  let(:t_start) { now }
  let(:t_end)   { now + 1.hour }

  describe "#call" do
    context "when cart is empty for the workspace" do
      it "returns false and adds error" do
        expect(service.call).to be false
        expect(service.errors).to include("No items in cart for this workspace.")
      end
    end

    context "when item is valid and capacity is available" do
      before do
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_start.iso8601, end_time: t_end.iso8601, quantity: 1)
      end

      it "creates a reservation" do
        expect {
          expect(service.call).to be true
        }.to change(Reservation, :count).by(1)

        res = Reservation.last
        expect(res.user).to eq(user)
        expect(res.item).to eq(item)
        expect(res.in_cart).to be false
      end

      it "clears the cart for that workspace" do
        service.call
        expect(cart.entries).to be_empty
      end

      it "enqueues notifications and reminders" do
        expect {
          service.call
        }.to change(Notification, :count).by(1)
         .and have_enqueued_job(ReservationReminderJob).twice
      end
    end

    context "when converting existing holds" do
      before do
        # Create a hold
        Reservation.create!(
          user: user, item: item, start_time: t_start, end_time: t_end,
          quantity: 1, in_cart: true, hold_expires_at: 10.minutes.from_now
        )
        # Add to cart (matching the hold)
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_start.iso8601, end_time: t_end.iso8601, quantity: 1)
      end

      it "converts the hold into a confirmed reservation" do
        # Should not increase count, just update/replace
        # Actually implementation deletes holds and creates new reservation, so ID changes but count stays same (1 -> 1)
        # Wait, create! adds 1, delete_all removes 1. So count is stable.
        
        expect {
          expect(service.call).to be true
        }.not_to change(Reservation, :count)

        res = Reservation.last
        expect(res.in_cart).to be false
        expect(res.hold_expires_at).to be_nil
      end
    end

    context "when capacity is full (and no holds)" do
      before do
        # Fill up capacity
        item.update!(quantity: 1)
        Reservation.create!(user: user, item: item, start_time: t_start, end_time: t_end, quantity: 1, in_cart: false)
        
        # Try to book same time
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_start.iso8601, end_time: t_end.iso8601, quantity: 1)
      end

      it "returns false and adds error" do
        expect(service.call).to be false
        expect(service.errors.join).to include("Not enough capacity")
      end
    end

    context "when user is blocked" do
      before do
        allow(user).to receive(:blocked_from_reserving_in?).with(workspace).and_return(true)
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_start.iso8601, end_time: t_end.iso8601, quantity: 1)
      end

      it "returns false and adds error" do
        expect(service.call).to be false
        expect(service.errors.join).to include("blocked from making reservations")
      end
    end

    context "when item no longer exists" do
      before do
        cart.add!(item_id: 99999, workspace_id: workspace.id, start_time: t_start.iso8601, end_time: t_end.iso8601, quantity: 1)
      end

      it "returns false and adds error" do
        expect(service.call).to be false
        expect(service.errors).to include("Item no longer exists.")
      end
    end

    context "when partial failure in transaction" do
      let(:item2) { Item.create!(name: "Other", quantity: 1, workspace: workspace, start_time: Time.zone.now.beginning_of_day, end_time: Time.zone.now.end_of_day) }

      before do
        # Item 1 is fine
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_start.iso8601, end_time: t_end.iso8601, quantity: 1)
        
        # Item 2 is fully booked
        Reservation.create!(user: user, item: item2, start_time: t_start, end_time: t_end, quantity: 1, in_cart: false)
        cart.add!(item_id: item2.id, workspace_id: workspace.id, start_time: t_start.iso8601, end_time: t_end.iso8601, quantity: 1)
      end

      it "rolls back all changes" do
        expect {
          expect(service.call).to be false
        }.not_to change(Reservation, :count) # Should not create reservation for item 1 either
        
        expect(cart.entries.size).to eq(2) # Cart should not be cleared
      end
    end
  end
end
