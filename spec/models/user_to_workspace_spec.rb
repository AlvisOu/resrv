require 'rails_helper'

RSpec.describe UserToWorkspace, type: :model do

  # --- Setup ---
  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "pw", password_confirmation: "pw") }
  let!(:workspace) { Workspace.create!(name: "Test Workspace") }

  # --- Associations ---
  describe "associations" do
    it "belongs to a user" do
      join = UserToWorkspace.new(user: user)
      expect(join.user).to eq(user)
    end

    it "belongs to a workspace" do
      join = UserToWorkspace.new(workspace: workspace)
      expect(join.workspace).to eq(workspace)
    end
  end

  # --- Role Validation ---
  describe "role validation" do
    context "when role is 'user'" do
      it "is valid" do
        join = UserToWorkspace.new(user: user, workspace: workspace, role: "user")
        expect(join).to be_valid
      end
    end

    context "when role is 'owner'" do
      it "is valid" do
        join = UserToWorkspace.new(user: user, workspace: workspace, role: "owner")
        expect(join).to be_valid
      end
    end

    context "when role is missing" do
      it "is invalid" do
        join = UserToWorkspace.new(user: user, workspace: workspace, role: nil)
        expect(join).not_to be_valid
        expect(join.errors[:role]).to include("can't be blank")
      end
    end

    context "when role is not in the allowed list" do
      it "is invalid" do
        join = UserToWorkspace.new(user: user, workspace: workspace, role: "admin")
        expect(join).not_to be_valid
        expect(join.errors[:role]).to include("is not included in the list")
      end
    end
  end

  # --- Scoped Uniqueness Validation ---
  describe "uniqueness validation (scope: :workspace_id)" do
    before do
      UserToWorkspace.create!(user: user, workspace: workspace, role: "user")
    end

    it "is invalid if the user is added to the same workspace again" do
      # Try to create a new record with the SAME user and SAME workspace
      duplicate_join = UserToWorkspace.new(user: user, workspace: workspace, role: "owner")
      
      expect(duplicate_join).not_to be_valid
      expect(duplicate_join.errors[:user_id]).to include("is already a member of this workspace")
    end

    it "is valid for a *different user* in the same workspace" do
      other_user = User.create!(name: "Other User", email: "other@example.com", password: "pw")
      
      # DIFFERENT user, SAME workspace
      join = UserToWorkspace.new(user: other_user, workspace: workspace, role: "user")
      expect(join).to be_valid
    end

    it "is valid for the *same user* in a different workspace" do
      other_workspace = Workspace.create!(name: "Other Workspace")
      
      # SAME user, DIFFERENT workspace
      join = UserToWorkspace.new(user: user, workspace: other_workspace, role: "user")
      expect(join).to be_valid
    end
  end
end
