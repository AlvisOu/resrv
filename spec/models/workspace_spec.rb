require 'rails_helper'

RSpec.describe Workspace, type: :model do
  # --- Validations ---
  describe "validations" do
    it "is valid with a name" do
      workspace = Workspace.new(name: "Engineering Workspace")
      expect(workspace).to be_valid
    end

    it "is invalid without a name" do
      workspace = Workspace.new(name: nil)
      expect(workspace).not_to be_valid
      expect(workspace.errors[:name]).to include("can't be blank")
    end
  end

  # --- Basic Associations ---
  describe "associations" do
    let!(:workspace) { Workspace.create!(name: "Test Workspace") }
    let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "pw") }
    
    it "has many items" do
      # Create an item associated with the workspace
      item = Item.create!(
        name: "Test Item", 
        workspace: workspace, 
        quantity: 1, 
        start_time: Time.zone.now, 
        end_time: Time.zone.now + 1.day
      )
      
      # Reload the workspace to get the association
      workspace.reload
      expect(workspace.items).to include(item)
    end

    it "has many users (through user_to_workspaces)" do
      # Create the join record
      UserToWorkspace.create!(user: user, workspace: workspace, role: "user")
      
      # Reload the workspace to get the association
      workspace.reload
      expect(workspace.users).to include(user)
    end
  end

  # --- Custom `has_one :owner` Association ---
  describe "custom association: owner" do
    let!(:workspace) { Workspace.create!(name: "Sales Workspace") }
    let!(:owner_user) { User.create!(name: "Owner", email: "owner@example.com", password: "pw") }
    let!(:member_user) { User.create!(name: "Member", email: "member@example.com", password: "pw") }

    context "when an owner exists" do
      it "returns the single owner user" do
        # Create an owner and a regular user
        UserToWorkspace.create!(user: owner_user, workspace: workspace, role: "owner")
        UserToWorkspace.create!(user: member_user, workspace: workspace, role: "user")
        
        workspace.reload
        expect(workspace.owner).to eq(owner_user)
      end
    end

    context "when only a non-owner user exists" do
      it "returns nil" do
        UserToWorkspace.create!(user: member_user, workspace: workspace, role: "user")
        
        workspace.reload
        expect(workspace.owner).to be_nil
      end
    end

    context "when no users are associated" do
      it "returns nil" do
        expect(workspace.owner).to be_nil
      end
    end
  end

  # --- `dependent: :destroy` Behavior ---
  describe "dependent: :destroy" do
    let!(:workspace) { Workspace.create!(name: "Deletable Workspace") }
    
    it "destroys associated items when destroyed" do
      # Create an item belonging to the workspace
      Item.create!(
        name: "Test Item", 
        workspace: workspace, 
        quantity: 1, 
        start_time: Time.zone.now, 
        end_time: Time.zone.now + 1.day
      )
      
      # Check that destroying the workspace reduces the Item count
      expect { workspace.destroy }.to change(Item, :count).by(-1)
    end

    it "destroys associated user_to_workspaces when destroyed" do
      # Create a user and associate them
      user = User.create!(name: "Test User", email: "test@example.com", password: "pw")
      UserToWorkspace.create!(user: user, workspace: workspace, role: "user")
      
      # Check that destroying the workspace reduces the UserToWorkspace count
      expect { workspace.destroy }.to change(UserToWorkspace, :count).by(-1)
    end
    
    it "does NOT destroy the users themselves" do
      # Create a user and associate them
      user = User.create!(name: "Test User", email: "test@example.com", password: "pw")
      UserToWorkspace.create!(user: user, workspace: workspace, role: "user")
      
      # Destroying the workspace should NOT change the User count
      expect { workspace.destroy }.not_to change(User, :count)
    end
  end
end
