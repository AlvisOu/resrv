require "rails_helper"

RSpec.describe Cart, type: :service do
  let(:workspace) { Workspace.create!(name: "Lab A") }
  let(:item) { Item.create!(name: "Microscope", quantity: 5, workspace: workspace,
                            start_time: Time.zone.now.beginning_of_day + 9.hours,
                            end_time:   Time.zone.now.beginning_of_day + 17.hours) }

  let(:session) { {} }

  describe ".load" do
    it "initializes an empty cart for the user" do
      cart = Cart.load(session, 1)
      expect(cart.entries).to eq([])
      expect(session[:carts]["1"]).to have_key("entries")
    end

    it "returns the same cart on subsequent loads" do
      c1 = Cart.load(session, 1)
      c1.add!(item_id: 42, workspace_id: 3, start_time: "2025-10-28T09:00:00Z", end_time: "2025-10-28T09:15:00Z", quantity: 1)
      c2 = Cart.load(session, 1)
      expect(c2.entries.size).to eq(1)
    end
  end

  describe "basic operations" do
    let(:cart) { Cart.load(session, 1) }

    it "adds entries and clamps quantity between 1 and 10" do
      cart.add!(item_id: 1, workspace_id: 2, start_time: "s", end_time: "e", quantity: 50)
      expect(cart.entries.first["quantity"]).to eq(10)

      cart.add!(item_id: 1, workspace_id: 2, start_time: "s", end_time: "e", quantity: 0)
      expect(cart.entries.last["quantity"]).to eq(1)
    end

    it "updates existing entry quantity" do
      cart.add!(item_id: 1, workspace_id: 2, start_time: "s", end_time: "e", quantity: 1)
      cart.update!(0, quantity: 7)
      expect(cart.entries.first["quantity"]).to eq(7)
    end

    it "raises ArgumentError on bad index update" do
      expect { cart.update!(9, quantity: 1) }.to raise_error(ArgumentError)
    end

    it "removes an entry by index" do
      cart.add!(item_id: 1, workspace_id: 2, start_time: "s", end_time: "e", quantity: 1)
      expect { cart.remove!(0) }.to change { cart.entries.size }.by(-1)
    end

    it "clears all entries" do
      2.times { cart.add!(item_id: 1, workspace_id: 2, start_time: "s", end_time: "e", quantity: 1) }
      cart.clear!
      expect(cart.entries).to be_empty
    end
  end

  describe "#clear_workspace!" do
    let(:session) { {} }
    let(:cart)    { Cart.load(session, 1) }

    before do
      # Store entries with a mix of string/int workspace_ids to exercise the .to_i comparison
      cart.add!(item_id: 1, workspace_id: '10', start_time: 's', end_time: 'e', quantity: 1) # string
      cart.add!(item_id: 2, workspace_id: 10,   start_time: 's', end_time: 'e', quantity: 1) # int
      cart.add!(item_id: 3, workspace_id: '20', start_time: 's', end_time: 'e', quantity: 1) # other workspace
    end

    it "deletes entries regardless of whether workspace_id is stored as string or integer" do
      cart = Cart.load({}, 1)
      
      # Store entries with mixed key types — exactly what happens in real sessions
      cart.add!(item_id: 1, workspace_id: "42", start_time: "s", end_time: "e", quantity: 1)
      cart.add!(item_id: 2, workspace_id: 42, start_time: "s", end_time: "e", quantity: 1)
      cart.add!(item_id: 3, workspace_id: "99", start_time: "s", end_time: "e", quantity: 1)

      # Call clear_workspace! using integer
      expect {
        cart.clear_workspace!(42)
      }.to change { cart.entries.size }.from(3).to(1)

      # Now call it again using string to ensure symmetric behavior
      cart.add!(item_id: 4, workspace_id: 99, start_time: "s", end_time: "e", quantity: 1)
      expect {
        cart.clear_workspace!("99")
      }.to change { cart.entries.size }.from(2).to(0)

      remaining_ids = cart.entries.map { |e| e["workspace_id"].to_i }
      expect(remaining_ids).not_to include(42, 99)
    end
  end

  describe "#remove_range!" do
    let(:cart) { Cart.load(session, 1) }
    let(:s1) { Time.zone.local(2025, 10, 28, 9, 0) }
    let(:s2) { Time.zone.local(2025, 10, 28, 9, 15) }
    let(:s3) { Time.zone.local(2025, 10, 28, 9, 30) }

    before do
      cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: s1.iso8601, end_time: s2.iso8601, quantity: 1)
      cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: s2.iso8601, end_time: s3.iso8601, quantity: 1)
      cart.add!(item_id: item.id, workspace_id: workspace.id + 1, start_time: s1.iso8601, end_time: s3.iso8601, quantity: 1)
    end

    it "removes entries fully inside given time range" do
      cart.remove_range!(item_id: item.id, workspace_id: workspace.id,
                         start_time: s1, end_time: s3)
      remaining = cart.entries
      expect(remaining.all? { |h| h["workspace_id"].to_i != workspace.id }).to be true
    end
  end

  describe "#entries_with_models and grouping" do
    let(:cart) { Cart.load(session, 1) }

    before do
      t1 = "2025-10-28T09:00:00Z"
      t2 = "2025-10-28T09:15:00Z"
      cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t1, end_time: t2, quantity: 2)
    end

    it "resolves item/workspace models correctly" do
      models = cart.entries_with_models
      expect(models.first[:item]).to eq(item)
      expect(models.first[:workspace]).to eq(workspace)
    end
  end

  describe "#merge_segments_for_item" do
    let(:cart) { Cart.load(session, 1) }

    it "merges adjacent segments and sums overlapping quantities" do
      now = Time.zone.local(2025, 10, 28, 9, 0)
      e1 = { item: item, workspace: workspace, start_time: now, end_time: now + 15.minutes, quantity: 1 }
      e2 = { item: item, workspace: workspace, start_time: now + 10.minutes, end_time: now + 25.minutes, quantity: 1 }

      merged = cart.merge_segments_for_item([e1, e2])
      expect(merged.map { |m| m[:quantity] }).to include(2) # overlap region
      expect(merged.first[:start_time]).to eq(now)
      expect(merged.last[:end_time]).to eq(now + 25.minutes)
    end

    it "coalesces adjacent segments with equal quantity" do
      now = Time.zone.local(2025, 10, 28, 9, 0)
      a = { item: item, workspace: workspace, start_time: now, end_time: now + 15.minutes, quantity: 1 }
      b = { item: item, workspace: workspace, start_time: now + 15.minutes, end_time: now + 30.minutes, quantity: 1 }
      merged = cart.merge_segments_for_item([a, b])
      expect(merged.size).to eq(1)
      expect(merged.first[:end_time]).to eq(now + 30.minutes)
    end
  end

  describe "#merged_segments_by_workspace" do
    it "returns a hash of workspace => merged segments" do
      cart = Cart.load(session, 1)
      t1 = Time.zone.local(2025, 10, 28, 9, 0)
      t2 = Time.zone.local(2025, 10, 28, 9, 15)
      cart.add!(item_id: item.id, workspace_id: workspace.id,
                start_time: t1.iso8601, end_time: t2.iso8601, quantity: 1)
      result = cart.merged_segments_by_workspace
      expect(result.keys).to include(workspace)
      expect(result[workspace].first).to include(:item, :quantity)
    end
  end

  describe "#total_count" do
    it "sums up quantities across all entries" do
      cart = Cart.load(session, 1)
      cart.add!(item_id: 1, workspace_id: 1, start_time: "s", end_time: "e", quantity: 3)
      cart.add!(item_id: 2, workspace_id: 1, start_time: "s", end_time: "e", quantity: 4)
      expect(cart.total_count).to eq(7)
    end
  end

  describe "#reservations_count" do
    it "returns the number of merged segments" do
      cart = Cart.load(session, 1)
      # Add two contiguous segments for the same item -> should merge into 1
      t1 = Time.zone.local(2025, 10, 28, 9, 0)
      t2 = Time.zone.local(2025, 10, 28, 9, 15)
      t3 = Time.zone.local(2025, 10, 28, 9, 30)
      
      cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t1.iso8601, end_time: t2.iso8601, quantity: 1)
      cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t2.iso8601, end_time: t3.iso8601, quantity: 1)
      
      expect(cart.reservations_count).to eq(1)

      # Add a separate segment (gap in time) -> should be a 2nd segment
      t4 = Time.zone.local(2025, 10, 28, 10, 0)
      t5 = Time.zone.local(2025, 10, 28, 10, 15)
      cart.add!(item_id: item.id, workspace_id: workspace.id, start_time: t4.iso8601, end_time: t5.iso8601, quantity: 1)

      expect(cart.reservations_count).to eq(2)
    end
  end

end
