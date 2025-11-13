require "rails_helper"

RSpec.describe ReservationsController, type: :controller do
  fixed_time = Time.zone.local(2025, 1, 1, 0, 0, 0)
  let(:workspace) { Workspace.create!(name: "Lab") }
  let(:item) do
    Item.create!(
      name: "Mic",
      workspace: workspace,
      quantity: 2,
      start_time: fixed_time + 6.hour,
      end_time: fixed_time + 23.hour
    )
  end
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:reservation) do
    Reservation.create!(
      user: user,
      item: item,
      start_time: fixed_time + 11.hour,
      end_time: fixed_time + 12.hour,
      quantity: 1,
      returned_count: 0
    )
  end

  before do
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:verified?).and_return(true)
  end

  # -------------------------------------------------------------------
  # AVAILABILITY
  # -------------------------------------------------------------------
  describe "GET #availability" do
    it "returns JSON with slots" do
      get :availability, params: { item_id: item.id, quantity: 1 }
      expect(response).to have_http_status(:success)

      data = JSON.parse(response.body)
      expect(data).to have_key("slots")
      expect(data["slots"]).to be_an(Array)
    end

    it "clamps day below today to today" do
      get :availability, params: { item_id: item.id, quantity: 1, day: "1900-01-01" }
      expect(response).to have_http_status(:success)
    end

    it "clamps day above max" do
      get :availability, params: { item_id: item.id, quantity: 1, day: (Date.today + 20).to_s }
      expect(response).to have_http_status(:success)
    end

    it "handles invalid date safely" do
      get :availability, params: { item_id: item.id, quantity: 1, day: "not-a-date" }
      expect(response).to have_http_status(:success)
    end
  end

  # -------------------------------------------------------------------
  # INDEX
  # -------------------------------------------------------------------
  describe "GET #index" do
    it "assigns user's reservations" do
      get :index
      expect(assigns(:reservations)).to include(reservation)
      expect(response).to render_template(:index)
    end
  end

  # -------------------------------------------------------------------
  # DESTROY
  # -------------------------------------------------------------------
  describe "DELETE #destroy" do
    it "deletes user's own reservation" do
      expect {
        delete :destroy, params: { id: reservation.id }
      }.to change(Reservation, :count).by(-1)

      expect(response).to redirect_to(reservations_path)
      expect(flash[:notice]).to eq("Reservation canceled successfully.")
    end

    it "raises error when deleting someone else's reservation" do
      outsider = User.create!(name: "Bob", email: "bob@example.com", password: "pw", password_confirmation: "pw")
      other_res = Reservation.create!(user: outsider, item: item, start_time: 3.hours.from_now, end_time: 4.hours.from_now)

      expect {
        delete :destroy, params: { id: other_res.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # -------------------------------------------------------------------
  # mark_no_show
  # -------------------------------------------------------------------
  describe "PATCH #mark_no_show" do
    before { allow(controller).to receive(:current_user_is_owner?).and_return(true) }

    it "marks a user as no-show and creates a penalty" do
      patch :mark_no_show, params: { id: reservation.id }

      reservation.reload
      expect(reservation.no_show).to eq(true)

      penalty = Penalty.last
      expect(penalty.reason).to eq("no_show")

      expect(response).to redirect_to(workspace)
      expect(flash[:notice]).to eq("#{user.name} marked as no-show.")
    end

    it "reverts a no-show and deletes penalty" do
      reservation.update!(no_show: true)
      Penalty.create!(user: user, reservation: reservation, workspace: workspace, reason: "no_show", expires_at: 3.days.from_now)

      patch :mark_no_show, params: { id: reservation.id }

      reservation.reload
      expect(reservation.no_show).to eq(false)
      expect(Penalty.find_by(reservation: reservation, reason: "no_show")).to be_nil
    end

    it "blocks non-owners" do
      allow(controller).to receive(:current_user_is_owner?).and_return(false)
      patch :mark_no_show, params: { id: reservation.id }

      expect(response).to redirect_to(workspace)
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  # -------------------------------------------------------------------
  # return_items
  # -------------------------------------------------------------------
  describe "PATCH #return_items" do
    before { allow(controller).to receive(:current_user_is_owner?).and_return(true) }

    it "rejects invalid quantity" do
      patch :return_items, params: { id: reservation.id, quantity_to_return: 0 }
      expect(flash[:alert]).to eq("Please enter a positive number.")
    end

    it "rejects returning more than reserved" do
      patch :return_items, params: { id: reservation.id, quantity_to_return: 5 }
      expect(flash[:alert]).to include("Cannot return more than reserved")
    end

    it "returns items successfully" do
      patch :return_items, params: { id: reservation.id, quantity_to_return: 1 }

      reservation.reload
      expect(reservation.returned_count).to eq(1)
      expect(flash[:notice]).to eq("1 Mic(s) returned successfully.")
    end

    it "creates a late return penalty" do
      reservation.update_columns(end_time: fixed_time + 14.hour)

      patch :return_items, params: { id: reservation.id, quantity_to_return: 1 }

      expect(Penalty.last.reason.to_s).to eq("late_return")
    end

    it "rescues and flashes error on failure" do
      allow_any_instance_of(Reservation).to receive(:update!).and_raise("boom")

      patch :return_items, params: { id: reservation.id, quantity_to_return: 1 }

      expect(flash[:alert]).to include("Failed to update status")
    end

    it "blocks non-owners" do
      allow(controller).to receive(:current_user_is_owner?).and_return(false)

      patch :return_items, params: { id: reservation.id, quantity_to_return: 1 }
      expect(response).to redirect_to(workspace)
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end

  # -------------------------------------------------------------------
  # undo_return_items
  # -------------------------------------------------------------------
  describe "PATCH #undo_return_items" do
    before do
      reservation.update!(returned_count: 1)
      allow(controller).to receive(:current_user_is_owner?).and_return(true)
    end

    it "rejects invalid quantity" do
      patch :undo_return_items, params: { id: reservation.id, quantity_to_undo: 0 }
      expect(flash[:alert]).to eq("Please enter a positive number.")
    end

    it "rejects undoing more than returned" do
      patch :undo_return_items, params: { id: reservation.id, quantity_to_undo: 5 }
      expect(flash[:alert]).to include("Cannot undo more than returned")
    end

    it "undoes return successfully" do
      patch :undo_return_items, params: { id: reservation.id, quantity_to_undo: 1 }
      reservation.reload
      expect(reservation.returned_count).to eq(0)
      expect(flash[:notice]).to eq("Undo return of 1 Mic(s) successful.")
    end

    it "rescues and flashes error on failure" do
      allow_any_instance_of(Reservation).to receive(:update!).and_raise("boom")

      patch :undo_return_items, params: { id: reservation.id, quantity_to_undo: 1 }
      expect(flash[:alert]).to include("Failed to update status")
    end

    it "blocks non-owners" do
      allow(controller).to receive(:current_user_is_owner?).and_return(false)

      patch :undo_return_items, params: { id: reservation.id, quantity_to_undo: 1 }
      expect(response).to redirect_to(workspace)
      expect(flash[:alert]).to eq("Not authorized.")
    end
  end
end
