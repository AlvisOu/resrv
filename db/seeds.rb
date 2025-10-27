puts "Destroying old data..."
Reservation.destroy_all
UserToWorkspace.destroy_all   # <- delete the join table first
Item.destroy_all
Workspace.destroy_all
User.destroy_all

# Helpers
today    = Time.zone.today
tomorrow = today + 1.day

puts "Creating users..."
admin = User.create!(
  name: "Admin User",
  email: "admin@resrv.com",
  password: "password123",
  password_confirmation: "password123"
)
member = User.create!(
  name: "Member User",
  email: "member@resrv.com",
  password: "password123",
  password_confirmation: "password123"
)
puts "Created #{User.count} users."

puts "Creating workspaces..."
gym = Workspace.create!(name: "Dodge Fitness Center")
auditorium = Workspace.create!(name: "Roone Auditorium")
puts "Created #{Workspace.count} workspaces."

puts "Creating UserToWorkspace..."
UserToWorkspace.create!(user: admin,  workspace: gym,        role: "owner")
UserToWorkspace.create!(user: admin,  workspace: auditorium, role: "owner")
UserToWorkspace.create!(user: member, workspace: gym,        role: "user")
UserToWorkspace.create!(user: member, workspace: auditorium, role: "user")
puts "Created #{UserToWorkspace.count} entries of UserToWorkspace."

puts "Creating items..."
treadmill = Item.create!(
  workspace:  gym,
  name:       "Treadmill",
  quantity:   5,
  start_time: today.beginning_of_day + 6.hours,   # 6:00 AM today (Rails zone)
  end_time:   today.beginning_of_day + 22.hours   # 10:00 PM today
)
lat_pulldown_machine = Item.create!(
  workspace:  gym,
  name:       "Lat Pulldown Machine",
  quantity:   1,
  start_time: today.beginning_of_day + 6.hours,
  end_time:   today.beginning_of_day + 22.hours
)
projector = Item.create!(
  workspace:  auditorium,
  name:       "4K Laser Projector",
  quantity:   1,
  start_time: today.beginning_of_day + 6.hours,
  end_time:   today.beginning_of_day + 23.hours
)
podium = Item.create!(
  workspace:  auditorium,
  name:       "Podium",
  quantity:   2,
  start_time: today.beginning_of_day + 6.hours,
  end_time:   today.beginning_of_day + 23.hours
)
puts "Created #{Item.count} items."

puts "Creating reservations..."
reservations = [
  {
    user: member,
    item: projector,
    start_time: today.noon,               # 12:00 PM today
    end_time:   today.noon + 2.hours      # 2:00 PM today
  },
  {
    user: member,
    item: lat_pulldown_machine,
    start_time: today.noon, # 9:00 AM tomorrow (fixed)
    end_time:   today.noon + 1.hour
  }
]
reservations.each { |attrs| Reservation.create!(attrs) }

puts "Created #{Reservation.count} reservations."
puts "Seed finished!"
