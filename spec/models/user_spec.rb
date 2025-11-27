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

  describe "password reset" do
    let(:user) { User.create!(name: "Test", email: "test@example.com", password: "pw") }

    describe "#send_password_reset_email" do
      it "generates a token, sets timestamp, and sends email" do
        expect {
          user.send_password_reset_email
        }.to change(ActionMailer::Base.deliveries, :count).by(1)

        expect(user.reset_token).to be_present
        expect(user.reset_sent_at).to be_present
      end
    end

    describe "#reset_password" do
      before do
        user.send_password_reset_email
      end

      it "resets the password if token is valid and not expired" do
        expect(user.reset_password("newpass", "newpass")).to be true
        expect(user.reload.authenticate("newpass")).to be_truthy
        expect(user.reset_token).to be_nil
        expect(user.reset_sent_at).to be_nil
      end

      it "fails if token is expired" do
        user.update!(reset_sent_at: 20.minutes.ago)
        expect(user.reset_password("newpass", "newpass")).to be false
        expect(user.errors[:reset_token]).to include("has expired")
      end

      it "fails if passwords do not match" do
        expect(user.reset_password("newpass", "mismatch")).to be false
        expect(user.errors[:password_confirmation]).to include("doesn't match Password")
      end
    end
  end

  describe "email verification" do
    let(:user) { User.create!(name: "Test", email: "test@example.com", password: "pw") }

    describe "#send_verification_email" do
      it "generates a code, sets timestamp, and sends email" do
        expect {
          user.send_verification_email
        }.to change(ActionMailer::Base.deliveries, :count).by(1)

        expect(user.verification_code).to be_present
        expect(user.verification_sent_at).to be_present
      end
    end

    describe "#verify_email_code" do
      before do
        user.send_verification_email
      end

      it "verifies if code is correct and not expired" do
        expect(user.verify_email_code(user.verification_code)).to be_truthy
        expect(user.email_verified_at).to be_present
        expect(user.verification_code).to be_nil
      end

      it "fails if code is incorrect" do
        expect(user.verify_email_code("wrong")).to be false
        expect(user.email_verified_at).to be_nil
      end

      it "fails if code is expired" do
        user.update!(verification_sent_at: 15.minutes.ago)
        expect(user.verify_email_code(user.verification_code)).to be false
        expect(user.email_verified_at).to be_nil
      end
    end

    describe "#verified?" do
      it "returns true if email_verified_at is present" do
        user.update!(email_verified_at: Time.now)
        expect(user.verified?).to be true
      end

      it "returns false if email_verified_at is nil" do
        expect(user.verified?).to be false
      end
    end
  end

  describe "penalties and blocking" do
    let(:user) { User.create!(name: "Test", email: "test@example.com", password: "pw") }
    let(:workspace) { Workspace.create!(name: "Lab") }
    let(:other_workspace) { Workspace.create!(name: "Other") }
    
    # Use fixed times within a standard day to avoid window issues
    let(:today_10am) { Time.zone.now.beginning_of_day + 10.hours }
    let(:today_11am) { Time.zone.now.beginning_of_day + 11.hours }
    
    let(:item) { 
      Item.create!(
        name: "Item", 
        workspace: workspace, 
        quantity: 1, 
        start_time: Time.zone.now.beginning_of_day + 9.hours, 
        end_time: Time.zone.now.beginning_of_day + 17.hours
      ) 
    }
    
    let(:reservation) { 
      Reservation.create!(
        user: user, 
        item: item, 
        start_time: today_10am, 
        end_time: today_11am
      ) 
    }

    describe "#blocked_from_reserving_in?" do
      it "returns false if no penalties" do
        expect(user.blocked_from_reserving_in?(workspace)).to be false
      end

      it "returns true if there is an active penalty for the workspace" do
        Penalty.create!(user: user, workspace: workspace, reason: "late_return", expires_at: 1.day.from_now)
        expect(user.blocked_from_reserving_in?(workspace)).to be true
      end

      it "returns false if penalty is expired" do
        Penalty.create!(user: user, workspace: workspace, reason: "late_return", expires_at: 1.day.ago)
        expect(user.blocked_from_reserving_in?(workspace)).to be false
      end

      it "returns false if penalty is for another workspace" do
        Penalty.create!(user: user, workspace: other_workspace, reason: "late_return", expires_at: 1.day.from_now)
        expect(user.blocked_from_reserving_in?(workspace)).to be false
      end
      
      it "handles penalties associated via reservation" do
        Penalty.create!(user: user, reservation: reservation, reason: "late_return", expires_at: 1.day.from_now)
        expect(user.blocked_from_reserving_in?(workspace)).to be true
      end
    end

    describe "#penalty_expiry_for" do
      it "returns the latest expiry date for the workspace" do
        t1 = 1.day.from_now
        t2 = 2.days.from_now
        Penalty.create!(user: user, workspace: workspace, reason: "late_return", expires_at: t1)
        Penalty.create!(user: user, workspace: workspace, reason: "no_show", expires_at: t2)
        
        expect(user.penalty_expiry_for(workspace).to_i).to eq(t2.to_i)
      end

      it "returns nil if no active penalties" do
        expect(user.penalty_expiry_for(workspace)).to be_nil
      end
    end
  end
end