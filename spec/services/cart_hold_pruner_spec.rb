require 'rails_helper'

RSpec.describe CartHoldPruner, type: :service do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "pw") }
  let(:workspace) { Workspace.create!(name: "Lab") }
  let(:item) { Item.create!(name: "Microscope", quantity: 5, workspace: workspace, start_time: Time.zone.now.beginning_of_day, end_time: Time.zone.now.end_of_day) }
  let(:session) { {} }
  let(:cart) { Cart.load(session, 1) }
  
  let(:now) { Time.zone.now.beginning_of_hour + 1.hour } # e.g. 10:00
  let(:t_1000) { now }
  let(:t_1015) { now + 15.minutes }
  let(:t_1030) { now + 30.minutes }
  let(:t_1100) { now + 60.minutes }

  describe ".prune!" do
    context "when cart has a segment with NO matching hold" do
      before do
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_1000.iso8601, end_time: t_1015.iso8601, quantity: 1)
      end

      it "removes the segment from the cart" do
        expect(cart.entries).not_to be_empty
        CartHoldPruner.prune!(cart, user.id)
        expect(cart.entries).to be_empty
      end
    end

    context "when cart has a segment fully covered by an active hold" do
      before do
        # Add to cart
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_1000.iso8601, end_time: t_1015.iso8601, quantity: 1)
        
        # Create matching hold
        Reservation.create!(
          user: user, item: item, start_time: t_1000, end_time: t_1015,
          quantity: 1, in_cart: true, hold_expires_at: 10.minutes.from_now
        )
      end

      it "keeps the segment in the cart" do
        CartHoldPruner.prune!(cart, user.id)
        expect(cart.entries.size).to eq(1)
      end
    end

    context "when hold is expired" do
      before do
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_1000.iso8601, end_time: t_1015.iso8601, quantity: 1)
        
        Reservation.create!(
          user: user, item: item, start_time: t_1000, end_time: t_1015,
          quantity: 1, in_cart: true, hold_expires_at: 10.minutes.ago
        )
      end

      it "removes the segment" do
        CartHoldPruner.prune!(cart, user.id)
        expect(cart.entries).to be_empty
      end
    end

    context "when hold only covers part of the time" do
      before do
        # Cart wants 10:00 - 10:30
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_1000.iso8601, end_time: t_1030.iso8601, quantity: 1)
        
        # Hold only covers 10:00 - 10:15
        Reservation.create!(
          user: user, item: item, start_time: t_1000, end_time: t_1015,
          quantity: 1, in_cart: true, hold_expires_at: 10.minutes.from_now
        )
      end

      it "removes the segment (or at least the uncovered part)" do
        # The implementation calls cart.remove_range! for the whole segment if not fully covered
        CartHoldPruner.prune!(cart, user.id)
        
        # Depending on implementation, it might remove the whole range or just the uncovered part.
        # The code says: unless fully_covered -> cart.remove_range!(... s_time, e_time)
        # So it removes the whole requested segment if ANY part is missing coverage.
        expect(cart.entries).to be_empty
      end
    end

    context "when hold has insufficient quantity" do
      before do
        # Cart wants quantity 2
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_1000.iso8601, end_time: t_1015.iso8601, quantity: 2)
        
        # Hold has quantity 1
        Reservation.create!(
          user: user, item: item, start_time: t_1000, end_time: t_1015,
          quantity: 1, in_cart: true, hold_expires_at: 10.minutes.from_now
        )
      end

      it "removes the segment" do
        CartHoldPruner.prune!(cart, user.id)
        expect(cart.entries).to be_empty
      end
    end

    context "with multiple segments and holds" do
      before do
        # Segment 1: 10:00-10:15 (Covered)
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_1000.iso8601, end_time: t_1015.iso8601, quantity: 1)
        Reservation.create!(user: user, item: item, start_time: t_1000, end_time: t_1015, quantity: 1, in_cart: true, hold_expires_at: 10.minutes.from_now)

        # Segment 2: 10:30-11:00 (Not Covered)
        cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t_1030.iso8601, end_time: t_1100.iso8601, quantity: 1)
      end

      it "keeps covered segments and removes uncovered ones" do
        CartHoldPruner.prune!(cart, user.id)
        
        # Should have 1 entry left (the first one)
        expect(cart.entries.size).to eq(1)
        entry = cart.entries.first
        expect(Time.iso8601(entry["start_time"])).to eq(t_1000)
      end
    end
  end
end
