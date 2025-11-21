# A lightweight cart stored entirely in the session.
# Structure:
# session[:cart] = {
#   "entries" => [
#     {
#       "item_id"      => 123,
#       "workspace_id" => 9,
#       "start_time"   => "2025-10-27T13:00:00Z",
#       "end_time"     => "2025-10-27T13:15:00Z",
#       "quantity"     => 2
#     }, ...
#   ]
# }
class Cart
  ENTRY_KEYS = %w[item_id workspace_id start_time end_time quantity].freeze

  def self.load(session, user_id = nil)
    session[:carts] ||= {}
    key = (user_id || :anonymous).to_s
    session[:carts][key] ||= { "entries" => [] }
    new(session[:carts][key])
  end

  def initialize(backing)
    @backing = backing
  end

  def entries
    @backing["entries"]
  end

  def add!(attrs)
    h = attrs.to_h.transform_keys(&:to_s)
    entry = h.slice(*ENTRY_KEYS)
    entry["quantity"] = entry["quantity"].to_i.clamp(1, 10)
    entries << entry
  end

  def update!(index, quantity:)
    i = index.to_i
    raise ArgumentError, "bad index" unless entries[i]
    entries[i]["quantity"] = quantity.to_i.clamp(1, 10)
  end

  def remove!(index)
    entries.delete_at(index.to_i)
  end

  def clear!
    entries.clear
  end

  # For rendering
  def entries_with_models
    # Resolve items/workspaces in one pass (avoid N+1)
    item_ids       = entries.map { _1["item_id"] }.uniq
    items_by_id    = Item.where(id: item_ids).includes(:workspace).index_by(&:id)
    entries.map.with_index do |e, idx|
      item = items_by_id[e["item_id"]]
      {
        index: idx,
        item: item,
        workspace: item&.workspace,
        start_time: Time.zone.parse(e["start_time"].to_s),
        end_time: Time.zone.parse(e["end_time"].to_s),
        quantity: e["quantity"].to_i
      }
    end
  end

  def total_count
    entries.sum { _1["quantity"].to_i }
  end
# Public: for the cart page
  def merged_segments_by_workspace
    # Hash: workspace => [segments...]
    entries_with_models
      .group_by { _1[:workspace] }
      .transform_values { |entries| merge_item_segments(entries) }
  end

  # entries: array of hashes from entries_with_models for a single workspace
  # Returns: array of merged segments across items, each:
  # { item:, workspace:, start_time:, end_time:, quantity: Integer }
  def merge_item_segments(entries)
    entries
      .group_by { _1[:item] }                # per item
      .flat_map { |_item, arr| merge_segments_for_item(arr) }
      .sort_by { |seg| [seg[:item]&.id || 0, seg[:start_time]] }
  end

  # arr: entries for one item (may overlap, varying quantities)
  # Produce piecewise-constant quantity segments by sweep line:
  # - Overlapping entries' quantities are summed in the overlap.
  # - Adjacent segments with the same quantity are merged.
  def merge_segments_for_item(arr)
    # Build +q at start, -q at end
    events = Hash.new(0)
    arr.each do |e|
      s = e[:start_time]
      t = e[:end_time]
      q = e[:quantity].to_i
      next if s.blank? || t.blank? || s >= t || q <= 0
      events[s] += q
      events[t] -= q
    end
    return [] if events.empty?

    # Sweep in chronological order
    times = events.keys.sort
    segments = []
    running = 0
    prev_time = nil

    times.each do |time|
      if prev_time && running > 0
        # we had a positive quantity from prev_time up to 'time'
        segments << {
          item: arr.first[:item],
          workspace: arr.first[:workspace],
          start_time: prev_time,
          end_time: time,
          quantity: running
        }
      end
      running += events[time]
      prev_time = time
    end

    # Merge adjacent segments with same quantity (touching endpoints)
    merged = []
    segments.each do |seg|
      if merged.any?
        last = merged[-1]
        if last[:item] == seg[:item] &&
           last[:end_time] == seg[:start_time] &&
           last[:quantity] == seg[:quantity]
          last[:end_time] = seg[:end_time] # coalesce
          next
        end
      end
      merged << seg
    end

    merged
  end

# Remove every entry that matches item/workspace and is fully inside [start_time, end_time)
    def remove_range!(item_id:, workspace_id:, start_time:, end_time:)
        s = Time.zone.parse(start_time.to_s)
        e = Time.zone.parse(end_time.to_s)

        @backing["entries"].delete_if do |h|
            (h["item_id"].to_i == item_id.to_i) &&
            (h["workspace_id"].to_i == workspace_id.to_i) &&
            (Time.zone.parse(h["start_time"].to_s) >= s) &&
            (Time.zone.parse(h["end_time"].to_s)   <= e)
        end
    end

    # Remove all entries for a given workspace id
    def clear_workspace!(workspace_id)
        @backing["entries"].delete_if { |h| h["workspace_id"].to_i == workspace_id.to_i }
    end
end