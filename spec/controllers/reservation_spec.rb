require 'rails_helper'

RSpec.describe ReservationsController, type: :controller do
  let(:workspace) { Workspace.create!(name: "Lab") }
  let(:item) { Item.create!(name: "Mic", workspace: workspace, quantity: 2, start_time: Time.zone.now.beginning_of_day, end_time: Time.zone.now.end_of_day) }
  let(:user) { User.create!(name: "Alice", email: "alice@example.com", password: "password123", password_confirmation: "password123") }
  let!(:reservation) { Reservation.create!(user: user, item: item, start_time: Time.zone.now + 1.hour, end_time: Time.zone.now + 2.hours) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #availability" do
    it "returns JSON with slots" do
      get :availability, params: { item_id: item.id, quantity: 1 }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key("slots")
    end
  end

  describe "GET #index" do
    it "assigns grouped reservations to @reservations" do
      get :index
      expect(assigns(:reservations)).to be_a(ActiveRecord::Relation)
      expect(assigns(:reservations).first).to eq(reservation)
      expect(response).to render_template(:index)
    end
  end

  describe "DELETE #destroy" do
    it "destroys a reservation belonging to the current user" do
      expect {
        delete :destroy, params: { id: reservation.id }
      }.to change(Reservation, :count).by(-1)
      expect(response).to redirect_to(reservations_path)
      expect(flash[:notice]).to eq("Reservation canceled successfully.")
    end

    it "does not allow deleting another user's reservation" do
      other_user = User.create!(name: "Bob", email: "bob@example.com", password: "pw", password_confirmation: "pw")
      other_reservation = Reservation.create!(user: other_user, item: item, start_time: Time.zone.now + 3.hours, end_time: Time.zone.now + 4.hours)

      expect {
        delete :destroy, params: { id: other_reservation.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
