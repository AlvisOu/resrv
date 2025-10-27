# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed (or created alongside the db with db:setup).
#

puts "Destroying old data..."
Reservation.destroy_all
Item.destroy_all
Workspace.destroy_all
User.destroy_all

# --- Users ---
puts "Creating users..."
admin = User.create!(
  name: "Admin User",
  email: "admin@resrv.com",
  password: "password123",
  password_confirmation: "password123"
)
# Never set password_digest manually thanks to has_secure_password macro
# Created_at and updated_at are automatically populated

member = User.create!(
  name: "Member User",
  email: "member@resrv.com",
  password: "password123",
  password_confirmation: "password123"
)
puts "Created #{User.count} users."

# --- Workspaces ---
puts "Creating workspaces..."
gym = Workspace.create!(name: "Dodge Fitness Center")

auditorium = Workspace.create!(
  name: "Roone Auditorium"
)
puts "Created #{Workspace.count} workspaces."

# --- UserToWorkspace ---
puts "Creating UserToWorkspace..."

UserToWorkspace.create!(user: admin, workspace: gym, role: "owner")
UserToWorkspace.create!(user: admin, workspace: auditorium, role: "owner")
UserToWorkspace.create!(user: member, workspace: gym, role: "user")
UserToWorkspace.create!(user: member, workspace: auditorium, role: "user")

puts "Created #{UserToWorkspace.count} entries of UserToWorkspace."

# --- Item ---
puts "Creating items..."

treadmill = Item.create!(
  workspace: gym,
  name: "Treadmill",
  quantity: 5,
  start_time: Date.today.beginning_of_day + 6.hours, # 6 AM
  end_time: Date.today.beginning_of_day + 22.hours # 10 PM
)
# Fine to use Date.today to seed as we care about the times only, but the dates

lat_pulldown_machine = Item.create!(
  workspace: gym,
  name: "Lat Pulldown Machine",
  quantity: 1,
  start_time: Date.today.beginning_of_day + 6.hours,
  end_time: Date.today.beginning_of_day + 22.hours
)

projector = Item.create!(
  workspace: auditorium,
  name: "4K Laser Projector",
  quantity: 1,
  start_time: Date.today.beginning_of_day + 6.hours,
  end_time: Date.today.beginning_of_day + 23.hours
)

podium = Item.create!(
  workspace: auditorium,
  name: "Podium",
  quantity: 2,
  start_time: Date.today.beginning_of_day + 6.hours,
  end_time: Date.today.beginning_of_day + 23.hours
)
puts "Created #{Item.count} items."

# --- Reservations ---
puts "Creating reservations..."

reservations = [
  {
    user: member,
    item: projector,
    start_time: 3.days.from_now.at_noon, # 12:00 PM three days from now
    end_time: 3.days.from_now.at_noon + 2.hours
  },
  {
    user: member,
    item: lat_pulldown_machine,
    start_time: 1.day.from_now.change(hour: 9), # 9:00 AM tomorrow
    end_time: 1.day.from_now.change(hour: 10)
  }
]

reservations.each do |reservation|
  Reservation.create!(reservation)
end

puts "Created #{Reservation.count} reservations."
puts "Seed finished!"