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

admin = User.create!(
  name: "Admin User",
  email: "admin@resrv.com",
  password: "password123",
  password_confirmation: "password123",
  email_verified_at: Time.current
)
member = User.create!(
  name: "Member User",
  email: "member@resrv.com",
  password: "password123",
  password_confirmation: "password123",
  email_verified_at: Time.current
)
alice = User.create!(
  name: "Alice Smith",
  email: "alice@resrv.com",
  password: "password123",
  password_confirmation: "password123",
  email_verified_at: Time.current
)
bob = User.create!(
  name: "Bob Jones",
  email: "bob@resrv.com",
  password: "password123",
  password_confirmation: "password123",
  email_verified_at: Time.current
)
demo = User.create!(
  name: "Demo",
  email: "demo@resrv.com",
  password: "password123",
  password_confirmation: "password123",
  email_verified_at: Time.current
)
puts "[Success] Created #{User.count} users."

gym        = Workspace.create!(name: "Dodge Fitness Center", description: "Campus gym with modern equipment and facilities.")
auditorium = Workspace.create!(name: "Roone Auditorium", description: "Main auditorium for events and lectures.")
library    = Workspace.create!(name: "Butler Library", description: "Main library on campus.")
broadway   = Workspace.create!(name: "Broadway Hall", description: "Junior and Senior Dorm rooms.")
puts "[Success] Created #{Workspace.count} workspaces."

UserToWorkspace.create!(user: admin,  workspace: gym,        role: "owner")
UserToWorkspace.create!(user: admin,  workspace: auditorium, role: "owner")
UserToWorkspace.create!(user: alice,  workspace: library,    role: "owner")
UserToWorkspace.create!(user: alice,  workspace: broadway,   role: "owner")

# Memberships
[member, alice, bob].each do |u|
  UserToWorkspace.create!(user: u, workspace: gym,        role: "user")
  UserToWorkspace.create!(user: u, workspace: auditorium, role: "user")
end
[admin, member, bob].each do |u|
  UserToWorkspace.create!(user: u, workspace: library, role: "user")
  UserToWorkspace.create!(user: u, workspace: broadway, role: "user")
end
puts "[Success] Created #{UserToWorkspace.count} entries of UserToWorkspace."

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
  quantity:   2,
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
puts "[Success] Created #{Item.count} items."

# Reservations
reservations = [
  # Member reservations
  { user: member, item: projector, start_time: today.noon, end_time: today.noon + 2.hours, quantity: 1 },
  { user: member, item: podium,    start_time: today.noon + 2.hours, end_time: today.noon + 3.hours, quantity: 1 },
  { user: member, item: lat_pulldown_machine, start_time: today.noon, end_time: today.noon + 1.hour, quantity: 1 },
  { user: member, item: dumbbells, start_time: today.noon, end_time: today.noon + 1.hour, quantity: 1 },
  
  # Past reservation
  { user: member, item: projector, start_time: (today - 7.days).noon, end_time: (today - 7.days).noon + 2.hours, quantity: 1 },

  # Alice reservations
  { user: alice, item: treadmill, start_time: today.beginning_of_day + 18.hours, end_time: today.beginning_of_day + 19.hours, quantity: 1 },
  { user: alice, item: mic,       start_time: tomorrow.noon, end_time: tomorrow.noon + 4.hours, quantity: 2 },

  # Bob reservations
  { user: bob, item: study_room, start_time: today.beginning_of_day + 14.hours, end_time: today.beginning_of_day + 16.hours, quantity: 1 },
  { user: bob, item: hdmi_cable, start_time: today.beginning_of_day + 14.hours, end_time: today.beginning_of_day + 16.hours, quantity: 1 },

  # Dorm reservations
  { user: member, item: desk_lamp, start_time: today.beginning_of_day + 10.hours, end_time: today.beginning_of_day + 12.hours, quantity: 1 },
  { user: alice, item: alarm_clock, start_time: today.beginning_of_day + 20.hours, end_time: today.beginning_of_day + 22.hours, quantity: 1 },
  { user: bob, item: desk_lamp, start_time: tomorrow.beginning_of_day + 9.hours, end_time: tomorrow.beginning_of_day + 11.hours, quantity: 1 },
  { user: admin, item: alarm_clock, start_time: tomorrow.beginning_of_day + 8.hours, end_time: tomorrow.beginning_of_day + 10.hours, quantity: 1 },
]

reservations.each do |attrs|
  Reservation.create!(attrs.merge(in_cart: false, hold_expires_at: nil))
end

# --- Analytics Demo Data (Dodge Fitness Center) ---
puts "Seeding analytics data for Dodge Fitness Center..."
analytics_users = [member, alice, bob, demo]

# Generate past reservations for the last 14 days
(1..14).each do |i|
  day_target = today - i.days
  
  # Treadmill: High usage (5 slots/day)
  [7, 9, 12, 17, 19].each do |h|
    Reservation.create!(
      user: analytics_users.sample,
      item: treadmill,
      start_time: day_target.beginning_of_day + h.hours,
      end_time: day_target.beginning_of_day + (h + 1).hours,
      quantity: 1,
      in_cart: false
    )
  end

  # Lat Pulldown: Medium usage (2 slots/day)
  [8, 18].each do |h|
    Reservation.create!(
      user: analytics_users.sample,
      item: lat_pulldown_machine,
      start_time: day_target.beginning_of_day + h.hours,
      end_time: day_target.beginning_of_day + (h + 1).hours,
      quantity: 1,
      in_cart: false
    )
  end

  # Dumbbells: Low usage (every other day)
  if i % 2 == 0
    Reservation.create!(
      user: analytics_users.sample,
      item: dumbbells,
      start_time: day_target.beginning_of_day + 15.hours,
      end_time: day_target.beginning_of_day + 16.hours,
      quantity: 1,
      in_cart: false
    )
  end
end
# --------------------------------------------------

puts "[Success] Created #{Reservation.count} reservations."
puts "[Success] Seed finished!"