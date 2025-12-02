# db/seeds.rb

MissingReport.destroy_all
Notification.destroy_all
Penalty.destroy_all
Reservation.destroy_all
UserToWorkspace.destroy_all
Item.destroy_all
Workspace.destroy_all
User.destroy_all
puts "[Success] Cleared existing data."

# Helpers
today    = Time.zone.today
tomorrow = today + 1.day
def create_missing_report_safe(item:, reservation:, workspace:, requested_qty:, **attrs)
  # You can only mark as missing what actually exists right now.
  # Clamp to current quantity, and also to reservation quantity if you want.
  max_by_stock       = item.quantity
  max_by_reservation = reservation.quantity
  max_qty            = [requested_qty, max_by_stock, max_by_reservation].min

  return if max_qty <= 0 # nothing to mark missing

  item.update!(quantity: item.quantity - max_qty)

  MissingReport.create!(
    reservation: reservation,
    item:        item,
    workspace:   workspace,
    quantity:    max_qty,
    **attrs
  )
end


# ----------------------------
# Users
# ----------------------------
admin = User.create!(
  name: "Admin User",
  email: "admin@resrv.com",
  password: "password123",
  password_confirmation: "password123",
)
member = User.create!(
  name: "Member User",
  email: "member@resrv.com",
  password: "password123",
  password_confirmation: "password123",
)
alice = User.create!(
  name: "Alice Smith",
  email: "alice@resrv.com",
  password: "password123",
  password_confirmation: "password123",
)
bob = User.create!(
  name: "Bob Jones",
  email: "bob@resrv.com",
  password: "password123",
  password_confirmation: "password123",
)
demo = User.create!(
  name: "Demo",
  email: "demo@resrv.com",
  password: "password123",
  password_confirmation: "password123"
)

# NEW USERS
charlie = User.create!(
  name: "Charlie Kim",
  email: "charlie@resrv.com",
  password: "password123",
  password_confirmation: "password123"
)
dana = User.create!(
  name: "Dana Lee",
  email: "dana@resrv.com",
  password: "password123",
  password_confirmation: "password123"
)
eve = User.create!(
  name: "Evelyn Chen",
  email: "eve@resrv.com",
  password: "password123",
  password_confirmation: "password123"
)

puts "[Success] Created #{User.count} users."

# ----------------------------
# Workspaces
# ----------------------------
gym        = Workspace.create!(name: "Dodge Fitness Center", description: "Campus gym with modern equipment and facilities.")
auditorium = Workspace.create!(name: "Roone Auditorium", description: "Main auditorium for events and lectures.")
library    = Workspace.create!(name: "Butler Library", description: "Main library on campus.")
broadway   = Workspace.create!(name: "Broadway Hall", description: "Junior and Senior Dorm rooms.")

# NEW WORKSPACES
makerspace = Workspace.create!(name: "Mudd Makerspace", description: "Engineering makerspace with tools for prototyping.")
music_room = Workspace.create!(name: "Music Practice Rooms", description: "Bookable rooms with pianos and basic recording equipment.")

puts "[Success] Created #{Workspace.count} workspaces."

# ----------------------------
# UserToWorkspace
# ----------------------------
UserToWorkspace.create!(user: admin,  workspace: gym,        role: "owner")
UserToWorkspace.create!(user: admin,  workspace: auditorium, role: "owner")
UserToWorkspace.create!(user: alice,  workspace: library,    role: "owner")
UserToWorkspace.create!(user: alice,  workspace: broadway,   role: "owner")

# NEW: owners for new workspaces
UserToWorkspace.create!(user: admin,  workspace: makerspace, role: "owner")
UserToWorkspace.create!(user: bob,    workspace: music_room, role: "owner")

# Existing memberships
[member, alice, bob].each do |u|
  UserToWorkspace.create!(user: u, workspace: gym,        role: "user")
  UserToWorkspace.create!(user: u, workspace: auditorium, role: "user")
end
[admin, member, bob].each do |u|
  UserToWorkspace.create!(user: u, workspace: library, role: "user")
  UserToWorkspace.create!(user: u, workspace: broadway, role: "user")
end

# NEW: memberships for new users and new workspaces
[charlie, dana, eve].each do |u|
  UserToWorkspace.create!(user: u, workspace: gym,        role: "user")
  UserToWorkspace.create!(user: u, workspace: makerspace, role: "user")
  UserToWorkspace.create!(user: u, workspace: music_room, role: "user")
end

puts "[Success] Created #{UserToWorkspace.count} entries of UserToWorkspace."

# ----------------------------
# Items
# ----------------------------

# Gym
treadmill = Item.create!(
  workspace:  gym,
  name:       "Treadmill",
  quantity:   5,
  start_time: today.beginning_of_day + 6.hours,   # 6:00 AM
  end_time:   today.beginning_of_day + 22.hours   # 10:00 PM
)
lat_pulldown_machine = Item.create!(
  workspace:  gym,
  name:       "Lat Pulldown Machine",
  quantity:   5,
  start_time: today.beginning_of_day + 6.hours,
  end_time:   today.beginning_of_day + 22.hours
)
dumbbells = Item.create!(
  workspace:  gym,
  name:       "Dumbbell Set (5-50lbs)",
  quantity:   3,
  start_time: today.beginning_of_day + 6.hours,
  end_time:   today.beginning_of_day + 22.hours
)

# Auditorium
projector = Item.create!(
  workspace:  auditorium,
  name:       "4K Laser Projector",
  quantity:   1,
  start_time: today.beginning_of_day + 8.hours,
  end_time:   today.beginning_of_day + 23.hours
)
podium = Item.create!(
  workspace:  auditorium,
  name:       "Podium",
  quantity:   2,
  start_time: today.beginning_of_day + 8.hours,
  end_time:   today.beginning_of_day + 23.hours
)
mic = Item.create!(
  workspace:  auditorium,
  name:       "Wireless Mic",
  quantity:   4,
  start_time: today.beginning_of_day + 8.hours,
  end_time:   today.beginning_of_day + 23.hours
)

# Library
study_room = Item.create!(
  workspace:  library,
  name:       "Group Study Room",
  quantity:   5,
  start_time: today.beginning_of_day,
  end_time:   today.end_of_day
)
hdmi_cable = Item.create!(
  workspace:  library,
  name:       "HDMI Cable",
  quantity:   10,
  start_time: today.beginning_of_day + 8.hours,
  end_time:   today.beginning_of_day + 20.hours
)

# Dorm
desk_lamp = Item.create!(
  workspace:  broadway,
  name:       "Desk Lamp",
  quantity:   15,
  start_time: today.beginning_of_day,
  end_time:   today.end_of_day
)
alarm_clock = Item.create!(
  workspace:  broadway,
  name:       "Alarm Clock",
  quantity:   10,
  start_time: today.beginning_of_day,
  end_time:   today.end_of_day
)

# NEW: Makerspace items
printer_3d = Item.create!(
  workspace:  makerspace,
  name:       "3D Printer",
  quantity:   3,
  start_time: today.beginning_of_day + 9.hours,
  end_time:   today.beginning_of_day + 21.hours
)
soldering_station = Item.create!(
  workspace:  makerspace,
  name:       "Soldering Station",
  quantity:   4,
  start_time: today.beginning_of_day + 9.hours,
  end_time:   today.beginning_of_day + 21.hours
)
vr_headset = Item.create!(
  workspace:  makerspace,
  name:       "VR Headset",
  quantity:   2,
  start_time: today.beginning_of_day + 9.hours,
  end_time:   today.beginning_of_day + 21.hours
)

# NEW: Music room items
upright_piano = Item.create!(
  workspace:  music_room,
  name:       "Upright Piano",
  quantity:   4,
  start_time: today.beginning_of_day + 8.hours,
  end_time:   today.beginning_of_day + 22.hours
)
recording_kit = Item.create!(
  workspace:  music_room,
  name:       "Recording Kit",
  quantity:   3,
  start_time: today.beginning_of_day + 8.hours,
  end_time:   today.beginning_of_day + 22.hours
)

puts "[Success] Created #{Item.count} items."

# ----------------------------
# Base Reservations (from your original seeds)
# ----------------------------
reservations = [
  # Member reservations
  { user: member, item: projector, start_time: today.noon, end_time: today.noon + 2.hours, quantity: 1 },
  { user: member, item: podium,    start_time: today.noon + 2.hours, end_time: today.noon + 3.hours, quantity: 1 },
  { user: member, item: lat_pulldown_machine, start_time: today.noon, end_time: today.noon + 1.hour, quantity: 1 },
  { user: member, item: dumbbells, start_time: today.noon, end_time: today.noon + 10.hours, quantity: 2 },

  # Past reservation
  { user: member, item: projector, start_time: (today - 7.days).noon, end_time: (today - 7.days).noon + 2.hours, quantity: 1 },

  # Alice reservations
  { user: alice, item: treadmill, start_time: today.beginning_of_day + 18.hours, end_time: today.beginning_of_day + 19.hours, quantity: 1 },
  { user: alice, item: mic,       start_time: tomorrow.noon, end_time: tomorrow.noon + 4.hours, quantity: 2 },

  # Bob reservations
  { user: bob, item: study_room, start_time: today.beginning_of_day + 14.hours, end_time: today.beginning_of_day + 16.hours, quantity: 1 },
  { user: bob, item: hdmi_cable, start_time: today.beginning_of_day + 14.hours, end_time: today.beginning_of_day + 16.hours, quantity: 1 },

  # Dorm reservations
  { user: member, item: desk_lamp,   start_time: today.beginning_of_day + 10.hours, end_time: today.beginning_of_day + 12.hours, quantity: 1 },
  { user: alice,  item: alarm_clock, start_time: today.beginning_of_day + 20.hours, end_time: today.beginning_of_day + 22.hours, quantity: 1 },
  { user: bob,    item: desk_lamp,   start_time: tomorrow.beginning_of_day + 9.hours, end_time: tomorrow.beginning_of_day + 11.hours, quantity: 1 },
  { user: admin,  item: alarm_clock, start_time: tomorrow.beginning_of_day + 8.hours, end_time: tomorrow.beginning_of_day + 10.hours, quantity: 1 },
]

reservations.each do |attrs|
  Reservation.create!(attrs.merge(
    in_cart: false,
    hold_expires_at: nil,
    no_show: false,
    returned_count: 0,
    stock_adjusted: false
  ))
end

# ----------------------------
# Analytics Demo Data (Dodge Fitness Center)
# ----------------------------
analytics_users = [member, alice, bob, demo]

# Generate past reservations for the last 30 days
(1..30).each do |i|
  day_target = today - i.days
  
  # Treadmill: Very High usage (8-12 slots/day)
  (7..21).to_a.sample(rand(8..12)).each do |h|
    Reservation.create!(
      user: analytics_users.sample,
      item: treadmill,
      start_time: day_target.beginning_of_day + h.hours,
      end_time: day_target.beginning_of_day + (h + 1).hours,
      quantity: 1,
      in_cart: false,
      hold_expires_at: nil,
      no_show: false,
      returned_count: 1,
      stock_adjusted: false
    )
  end

  # Lat Pulldown: High usage (5-8 slots/day)
  (7..20).to_a.sample(rand(5..8)).each do |h|
    Reservation.create!(
      user: analytics_users.sample,
      item: lat_pulldown_machine,
      start_time: day_target.beginning_of_day + h.hours,
      end_time: day_target.beginning_of_day + (h + 1).hours,
      quantity: 1,
      in_cart: false,
      hold_expires_at: nil,
      no_show: false,
      returned_count: 1,
      stock_adjusted: false
    )
  end

  # Dumbbells: Medium usage (3-5 slots/day)
  (8..19).to_a.sample(rand(3..5)).each do |h|
    qty = rand(1..2)
    Reservation.create!(
      user: analytics_users.sample,
      item: dumbbells,
      start_time: day_target.beginning_of_day + h.hours,
      end_time: day_target.beginning_of_day + (h + 1).hours,
      quantity: qty, # Sometimes reserve 2 sets
      in_cart: false,
      hold_expires_at: nil,
      no_show: false,
      returned_count: qty,
      stock_adjusted: false
    )
  end
end

# ----------------------------
# NEW: Extra reservations for new users (20+ each)
# ----------------------------
new_users = [charlie, dana, eve]

all_bookable_items = [
  treadmill, lat_pulldown_machine, dumbbells,
  projector, podium, mic,
  study_room, hdmi_cable,
  desk_lamp, alarm_clock,
  printer_3d, soldering_station, vr_headset,
  upright_piano, recording_kit
]

new_users.each do |user|
  22.times do
    item = all_bookable_items.sample

    # derive allowed hours from the item's availability
    start_hour = item.start_time.hour
    end_hour   = item.end_time.hour - 1

    next if end_hour < start_hour  # fail-safe

    hour       = rand(start_hour..end_hour)
    day_offset = rand(0..10)
    day        = today - day_offset.days

    start_time = day.beginning_of_day + hour.hours
    end_time   = start_time + 1.hour

    # Only put in cart if the hold wouldn't be expired (start - 2h > now)
    # This prevents "Notification Create" logs for expired holds immediately after seeding.
    can_be_in_cart = start_time > (Time.current + 2.hours)
    in_cart        = can_be_in_cart && [true, false].sample
    hold_exp       = in_cart ? (start_time - 2.hours) : nil
    
    # Logic for past/future status
    if start_time > Time.current
      # Future
      no_show  = false
      returned = 0
    else
      # Past - ensure returned to avoid negative stock
      in_cart  = false
      hold_exp = nil
      no_show  = false
      returned = 1
    end

    begin
      Reservation.create!(
        user: user,
        item: item,
        start_time: start_time,
        end_time: end_time,
        quantity: 1,
        in_cart: in_cart,
        hold_expires_at: hold_exp,
        no_show: no_show,
        returned_count: returned,
        stock_adjusted: false
      )
    rescue ActiveRecord::RecordInvalid => e
      # Ignore capacity errors during random seeding
      puts "Skipping reservation due to validation error: #{e.message}"
    end
  end
end


# ----------------------------
# NEW: Missing reports (no quantity below 0)
# ----------------------------
# Example: Past treadmill reservation with missing quantity
treadmill_res = Reservation.where(item: treadmill).order(:start_time).first
if treadmill_res
  create_missing_report_safe(
    item:          treadmill,
    reservation:   treadmill_res,
    workspace:     gym,
    requested_qty: 1, # you can bump this up; it will clamp automatically
    resolved:      false,
    status:        "pending",
    reported_at:   treadmill_res.end_time + 30.minutes
  )
end

# Example: Mic reservation partially returned but then resolved
mic_res = Reservation.where(item: mic).order(:start_time).first
if mic_res
  create_missing_report_safe(
    item:          mic,
    reservation:   mic_res,
    workspace:     auditorium,
    requested_qty: 1,
    resolved:      true,
    status:        "resolved",
    reported_at:   mic_res.end_time + 1.hour
  )

  # If you want resolution to restock, you can optionally add back:
  # mic.update!(quantity: mic.quantity + 1)
end

puts "[Success] Created #{MissingReport.count} missing reports."

# ----------------------------
# NEW: Penalties & Notifications
# ----------------------------
# Look up the inclusion validator on :reason so we always use valid values
reason_validator = Penalty.validators_on(:reason)
  .grep(ActiveModel::Validations::InclusionValidator)
  .first

allowed_reasons = reason_validator&.options&.dig(:in) || []
default_reason  = allowed_reasons.first

# Look up the inclusion validator on :appeal_state as well
appeal_validator = Penalty.validators_on(:appeal_state)
  .grep(ActiveModel::Validations::InclusionValidator)
  .first

allowed_appeal_states = appeal_validator&.options&.dig(:in) || []
default_appeal_state  = allowed_appeal_states.first

if default_reason.nil? || default_appeal_state.nil?
  puts "[Warning] No allowed reasons or appeal_states configured for Penalty; skipping penalty seeding."
else
  # Try to pick more descriptive reasons if such values exist in your list
  late_reason   = allowed_reasons.find { |r| r.to_s.include?("late") }   || default_reason
  damage_reason = allowed_reasons.find { |r| r.to_s.include?("damage") } || default_reason

  late_reservation = Reservation.where(user: member).order(:end_time).first

  if late_reservation
    penalty = Penalty.create!(
      user:        member,
      reservation: late_reservation,
      workspace:   late_reservation.item.workspace,
      reason:      late_reason,
      expires_at:  1.month.from_now,
      appeal_state: default_appeal_state
    )

    Notification.create!(
      user:        member,
      reservation: late_reservation,
      penalty:     penalty,
      message:     "You received a penalty for reservation ##{late_reservation.id}.",
      read:        false
    )
  end

  # Another example: penalty for makerspace reservation
  makerspace_res = Reservation.where(item: printer_3d).order(:end_time).first
  if makerspace_res
    penalty2 = Penalty.create!(
      user:        makerspace_res.user,
      reservation: makerspace_res,
      workspace:   makerspace_res.item.workspace,
      reason:      damage_reason,
      expires_at:  2.months.from_now,
      appeal_state: default_appeal_state,
      appeal_message: "I believe the damage was pre-existing.",
      appealed_at: Time.current
    )

    Notification.create!(
      user:        makerspace_res.user,
      reservation: makerspace_res,
      penalty:     penalty2,
      message:     "A penalty has been issued for this reservation. You may appeal this decision.",
      read:        false
    )
  end
end

puts "[Success] Created #{Penalty.count} penalties."
puts "[Success] Created #{Notification.count} notifications."
puts "[Success] Created #{Reservation.count} reservations in total."
puts "[Success] Seed finished!"

# ----------------------------
# Final sanity pass: no negative item quantities
# ----------------------------
Item.find_each do |item|
  if item.quantity && item.quantity < 0
    puts "[Warning] Item #{item.name} had negative quantity #{item.quantity}, clamping to 0."
    item.update_column(:quantity, 0)
  end
end
