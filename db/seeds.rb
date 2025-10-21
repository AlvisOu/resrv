# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

movies = [{ title: 'Aladdin', rating: 'G', release_date: '25-Nov-1992' },
          { title: 'The Terminator', rating: 'R', release_date: '26-Oct-1984' },
          { title: 'When Harry Met Sally', rating: 'R', release_date: '21-Jul-1989' },
          { title: 'The Help', rating: 'PG-13', release_date: '10-Aug-2011' },
          { title: 'Chocolat', rating: 'PG-13', release_date: '5-Jan-2001' },
          { title: 'Amelie', rating: 'R', release_date: '25-Apr-2001' },
          { title: '2001: A Space Odyssey', rating: 'G', release_date: '6-Apr-1968' },
          { title: 'The Incredibles', rating: 'PG', release_date: '5-Nov-2004' },
          { title: 'Raiders of the Lost Ark', rating: 'PG', release_date: '12-Jun-1981' },
          { title: 'Chicken Run', rating: 'G', release_date: '21-Jun-2000' }]

movies.each do |movie|
  Movie.create!(movie)
end


puts "Destroying old data..."
Reservation.destroy_all
Equipment.destroy_all
Workspace.destroy_all
User.destroy_all
# Movie.destroy_all

# --- Users ---
puts "Creating users..."
admin = User.create!(
  name: "Admin User",
  email: "admin@resrv.com",
  password: "password123",
  password_confirmation: "password123",
  role: "admin",
  active: true
)

member = User.create!(
  name: "Member User",
  email: "member@resrv.com",
  password: "password123",
  password_confirmation: "password123",
  role: "user",
  active: true
)
puts "Created #{User.count} users."

# --- Workspaces ---
puts "Creating workspaces..."
gym = Workspace.create!(
  name: "Dodge Fitness Center",
  slug: "dodge-fitness-center",
  description: "Full-service fitness center with cardio, weights, and a pool.",
  timezone: "Eastern Time (US & Canada)"
)

auditorium = Workspace.create!(
  name: "Roone Auditorium",
  slug: "roone-auditorium",
  description: "300-seat venue for plays, concerts, and presentations.",
  timezone: "Eastern Time (US & Canada)"
)
puts "Created #{Workspace.count} workspaces."

# --- Equipment ---
puts "Creating equipment..."

treadmill = Equipment.create!(
  workspace: gym,
  name: "Treadmill",
  description: "ProForm 9000 Treadmill with iFit.",
  quantity: 5,
  active: true
)

lat_pulldown_machine = Equipment.create!(
  workspace: gym,
  name: "Lat Pulldown Machine",
  description: "Standard lat pulldown machine with adjustable weights.",
  quantity: 1,
  active: true
)

projector = Equipment.create!(
  workspace: auditorium,
  name: "4K Laser Projector",
  description: "Ceiling-mounted 4K projector for presentations.",
  quantity: 1,
  active: true
)

podium = Equipment.create!(
  workspace: auditorium,
  name: "Podium",
  description: "Wooden podium with microphone and light.",
  quantity: 2,
  active: true
)
puts "Created #{Equipment.count} pieces of equipment."

# --- Reservations ---
puts "Creating reservations..."

reservations = [
  {
    user: member,
    equipment: treadmill,
    start_at: 2.days.ago,
    end_at: 2.days.ago + 1.hour,
    quantity: 1,
    status: "confirmed",
    notes: "My first run on the new system."
  },
  {
    user: member,
    equipment: projector,
    start_at: 3.days.from_now.at_noon, # 12:00 PM three days from now
    end_at: 3.days.from_now.at_noon + 2.hours,
    quantity: 1,
    status: "pending",
    notes: "Tech setup for my talk. Will need help."
  },
  {
    user: admin,
    equipment: lat_pulldown_machine,
    start_at: 1.day.from_now.change(hour: 9), # 9:00 AM tomorrow
    end_at: 1.day.from_now.change(hour: 10),
    quantity: 1,
    status: "confirmed"
  }
]

reservations.each do |reservation|
  Reservation.create!(reservation)
end

puts "Created #{Reservation.count} reservations."
puts "Seed finished!"