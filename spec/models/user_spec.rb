require 'rails_helper'

RSpec.describe User, type: :model do
  
  # Validations
  describe "validations" do
    context "with valid attributes" do
      it "is valid" do
        user = User.create(
          name: "Test User",
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        expect(user).to be_valid
      end
    end

    context "with invalid attributes" do
      it "is invalid without a name" do
        user = User.new(
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("can't be blank")
      end

      it "is invalid without an email" do
        user = User.new(
          name: "Test User",
          password: "password123",
          password_confirmation: "password123"
        )
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it "is invalid with a bad email format" do
        user = User.new(
          name: "Test User",
          email: "not-an-email",
          password: "password123",
          password_confirmation: "password123"
        )
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("must be a valid email address")
      end

      it "is invalid with a duplicate email" do
        User.create(
          name: "Test User",
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        user = User.new(
          name: "Another User",
          email: "TEST@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("has already been taken")
      end
    end
  end

  # Secure Password
  describe "password (from has_secure_password)" do
    it "is invalid without a password" do
      user = User.new(
        name: "Test User",
        email: "test@example.com",
        password: "",
        password_confirmation: ""
      )
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "is invalid when password and confirmation do not match" do
      user = User.new(
        name: "Test User",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "different_password"
      )
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("doesn't match Password")
    end

    it "creates a password digest when a valid password is provided" do
      user = User.create(
        name: "Test User",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      expect(user).to be_valid
      expect(user.password_digest).not_to be_nil
    end
  end

  # Associations
  describe "associations" do
    let!(:user) { User.create(name: "Test User", email: "test@example.com", password: "password123", password_confirmation: "password123") }
    let!(:workspace) { Workspace.create(name: "Test Workspace") }
    let(:now) { Time.zone.local(2025, 10, 28, 10, 0, 0) }
    let!(:item) { Item.create(name: "Test Item", workspace: workspace, quantity: 1, start_time: now, end_time: now + 1.hour) }
    
    it "has many reservations" do
      reservation = Reservation.create(user: user, item: item, start_time: now, end_time: now + 30.minutes)
      expect(user.reservations).to include(reservation)
    end

    it "has many workspaces through user_to_workspaces" do
      UserToWorkspace.create(user: user, workspace: workspace, role: "user")
      user.reload
      expect(user.workspaces).to include(workspace)
    end
  end

  describe "custom role associations" do
    let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "pw") }
    
    let!(:owned_space) { Workspace.create!(name: "Owned Workspace") }
    let!(:joined_space) { Workspace.create!(name: "Joined Workspace") }
    
    before do
      UserToWorkspace.create!(user: user, workspace: owned_space, role: "owner")
      UserToWorkspace.create!(user: user, workspace: joined_space, role: "user")
      user.reload
    end

    it "includes the correct workspace in owned_workspaces" do
      expect(user.owned_workspaces).to include(owned_space)
      expect(user.owned_workspaces).not_to include(joined_space)
    end

    it "includes the correct workspace in joined_workspaces" do
      expect(user.joined_workspaces).to include(joined_space)
      expect(user.joined_workspaces).not_to include(owned_space)
    end
  end

  # Destroy behavior
  describe "dependent destroy" do
    let!(:user) { User.create!(name: "Test", email: "test@example.com", password: "pw") }
    let!(:workspace) { Workspace.create!(name: "Test Space") }
    let(:now) { Time.zone.local(2025, 10, 28, 10, 0, 0) }
    let!(:item) { Item.create!(name: "Test Item", workspace: workspace, quantity: 1, start_time: now, end_time: now + 5.hour) }

    it "destroys associated reservations" do
      Reservation.create!(user: user, item: item, start_time: now, end_time: now + 1.hour)
      
      expect { user.destroy }.to change(Reservation, :count).by(-1)
    end

    it "destroys associated user_to_workspaces" do
      UserToWorkspace.create!(user: user, workspace: workspace, role: "user")
      

      expect { user.destroy }.to change(UserToWorkspace, :count).by(-1)
    end
  end
end