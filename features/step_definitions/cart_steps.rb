# --- Givens ---
Given("my cart already contains 1 selection") do
  workspace = Workspace.find_or_create_by!(name: "Lerner Auditorium")
  item = Item.find_or_create_by!(name: "Mic", workspace: workspace) do |it|
    it.quantity   = 10
    it.start_time = Time.zone.today.beginning_of_day
    it.end_time   = Time.zone.today.end_of_day
  end

  selections = [
    {
      item_id: item.id,
      workspace_id: workspace.id,
      start_time: (Time.zone.now + 30.minutes).change(sec: 0).iso8601,
      end_time:   (Time.zone.now + 45.minutes).change(sec: 0).iso8601,
      quantity: 1
    }
  ]
  add_item_to_cart(selections)
end
Given("my cart contains the following selections:") do |table|
  workspace = Workspace.find_or_create_by!(name: "Lerner Auditorium")
  item = Item.find_or_create_by!(name: "Mic", workspace: workspace) do |it|
    it.quantity   = 10
    it.start_time = Time.zone.today.beginning_of_day
    it.end_time   = Time.zone.today.end_of_day
  end

  selections = table.hashes.map do |h|
    {
      item_id: (h["item_id"].presence || item.id).to_i.nonzero? || item.id,
      workspace_id: (h["workspace_id"].presence || workspace.id).to_i.nonzero? || workspace.id,
      start_time: h["start_time"],
      end_time:   h["end_time"],
      quantity:   h["quantity"].to_i
    }
  end
  add_item_to_cart(selections)
end

# --- Sees ---
Then /^(?:|I )should see my pending reservation$/ do
  page.should have_content("Your Cart")
  page.should have_content("Mic")
  page.should have_content("1")
end


Given("an expired in-cart hold for {string} exists for {string}") do |item_name, user_name|
  user = User.find_by!(name: user_name)
  item = Item.find_by!(name: item_name)

  item_start = item.start_time
  item_end = item.end_time

  window_duration = item_end - item_start
  reservation_start = item_start + (window_duration * 0.25)
  reservation_end   = item_start + (window_duration * 0.5)

  @expired_hold = Reservation.create!(
    user: user,
    item: item,
    start_time: reservation_start,
    end_time: reservation_end,
    quantity: 1,
    start_time: start_window + 1.hour,
    end_time:   start_window + 2.hours,
    in_cart: true,
    created_at: 5.hours.ago,
    hold_expires_at: 4.hours.ago
  )
end

When('I run the PurgeExpiredHolds job') do
  PurgeExpiredHoldsJob.perform_now
end

Then('the expired in-cart hold should be removed') do
  expect(Reservation.where(id: @expired_hold.id)).not_to exist
end

# A tiny cart double the service expects
class TestCart
  attr_reader :groups, :cleared
  def initialize(groups)      # { workspace => [segments] }
    @groups = groups
    @cleared = []
  end
  def merged_segments_by_workspace
    @groups
  end
  def clear_workspace!(workspace_id)
    @cleared << workspace_id
  end
end

def tz_parse_today(hhmm)
  Time.zone.parse("#{Time.zone.today} #{hhmm}")
end

Given('an empty checkout cart for workspace {int}') do |wid|
  @cart = TestCart.new({})      # no groups -> segments.blank? hits
  @workspace_id = wid
end

Given('a checkout cart for {string} with a segment for {string} from {string} to {string} qty {int}') do |ws_name, item_name, s_str, e_str, q|
  ws = Workspace.find_by!(name: ws_name)
  item = Item.find_by!(name: item_name, workspace: ws)
  s = tz_parse_today(s_str)
  e = tz_parse_today(e_str)
  seg = { item: item, start_time: s, end_time: e, quantity: q }
  @cart = TestCart.new({ ws => [seg] })
  @workspace_id = ws.id
end

# Make the named user appear blocked from reserving in the named workspace.
Given(/^the user "([^"]+)" is blocked in "([^"]+)"$/) do |full_name, ws_name|
  user = User.find_by!(name: full_name)
  ws   = Workspace.find_by!(name: ws_name)

  # No RSpec mocks needed—override the instance method for this user.
  user.define_singleton_method(:blocked_from_reserving_in?) do |workspace|
    workspace.id == ws.id
  end

  @user = user
end


Given('{string} has quantity {int}') do |item_name, qty|
  item = Item.find_by!(name: item_name)
  item.update!(quantity: qty)
end

Given('another user has a reservation for {string} from {string} to {string} qty {int}') do |item_name, s_str, e_str, q|
  other = User.find_or_create_by!(email: 'other@example.com') { |u| u.name = 'Other User'; u.password = 'password' }
  item  = Item.find_by!(name: item_name)
  Reservation.create!(
    user: other, item: item,
    start_time: tz_parse_today(s_str),
    end_time:   tz_parse_today(e_str),
    quantity:   q,
    in_cart:    false
  )
end

Given('the user {string} has an in-cart hold for {string} from {string} to {string} qty {int}') do |full_name, item_name, s_str, e_str, q|
  u    = User.find_by!(name: full_name)
  item = Item.find_by!(name: item_name)
  Reservation.create!(
    user: u, item: item,
    start_time: tz_parse_today(s_str),
    end_time:   tz_parse_today(e_str),
    quantity:   q,
    in_cart:    true,
    hold_expires_at: 30.minutes.from_now # not expired -> considered in convert_user_holds!
  )
end


When('I run checkout for {string} and workspace {string}') do |full_name, ws_name|
  user = @user || User.find_by!(name: full_name)   # <-- reuse the overridden instance
  ws   = Workspace.find_by!(name: ws_name)
  @service = CheckoutService.new(@cart, user, ws.id)
  @result  = @service.call
end

When('I run checkout for {string} and workspace {int}') do |full_name, wid|
  user = @user || User.find_by!(name: full_name)
  @service = CheckoutService.new(@cart, user, wid)
  @result  = @service.call
end


Then('the checkout should fail with {string}') do |message|
  expect(@result).to be(false)
  expect(@service.errors.join("\n")).to include(message)
end

Then('no new reservations should exist for {string}') do |full_name|
  user = User.find_by!(name: full_name)
  expect(Reservation.where(user: user).count).to eq(Reservation.where(user: user, in_cart: true).count)
end

When('I call the private capacity helper for {string} from {string} to {string} qty {int}') do |item_name, s_str, e_str, q|
  item = Item.find_by!(name: item_name)
  s = tz_parse_today(s_str)
  e = tz_parse_today(e_str)
  # a harmless cart/workspace to build the service object
  @service ||= CheckoutService.new(TestCart.new({}), @user, @workspace&.id || @workspace_id)
  @cap_ok = @service.send(:capacity_available?, item, s, e, q)
end

Then('it should report capacity available') do
  expect(@cap_ok).to be(true)
end

Then('it should report capacity unavailable') do
  expect(@cap_ok).to be(false)
end
