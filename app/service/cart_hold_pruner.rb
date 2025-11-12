# app/services/cart_hold_pruner.rb
require "set"

class CartHoldPruner
  SLOT = 15.minutes

  # Remove cart entries that are NOT fully covered by active holds (by time & quantity)
  def self.prune!(cart, user_id)
    now = Time.zone.now
    groups = cart.merged_segments_by_workspace

    groups.each do |workspace, segs|
      segs.each do |seg|
        item   = seg[:item]
        next unless item

        seg_qty = seg[:quantity].to_i.nonzero? || 1
        s_time  = normalize_time(seg[:start_time])
        e_time  = normalize_time(seg[:end_time])

        # Pull all active holds that overlap the segment
        holds = Reservation.where(
          "user_id = ? AND item_id = ? AND in_cart = TRUE AND hold_expires_at > ? AND start_time < ? AND end_time > ?",
          user_id, item.id, now, e_time, s_time
        ).pluck(:start_time, :end_time, :quantity)

        # Build coverage per 15-min tick: sum of quantities covering that tick
        coverage = Hash.new(0)
        holds.each do |hs, he, q|
          t = round_down(hs)
          he_ceil = round_up(he)
          while t < he_ceil
            coverage[t.to_i] += q.to_i
            t += SLOT
          end
        end

        # Check every tick in the cart segment has enough quantity coverage
        fully_covered = true
        t = round_down(s_time)
        seg_end_ceil = round_up(e_time)
        while t < seg_end_ceil
          if coverage[t.to_i] < seg_qty
            fully_covered = false
            break
          end
          t += SLOT
        end

        unless fully_covered
          cart.remove_range!(
            item_id:      item.id,
            workspace_id: seg[:workspace]&.id,
            start_time:   s_time.iso8601,
            end_time:     e_time.iso8601
          )
        end
      end
    end

    true
  end

  def self.normalize_time(x)
    return x.to_time if x.respond_to?(:to_time)
    Time.iso8601(x)
  end

  def self.round_down(t)
    t = t.change(sec: 0)
    t - (t.min % 15).minutes
  end

  def self.round_up(t)
    t = t.change(sec: 0)
    rem = (15 - (t.min % 15)) % 15
    rem.zero? ? t : t + rem.minutes
  end
end
