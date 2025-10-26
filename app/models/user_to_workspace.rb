class UserToWorkspace < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  enum role: {
    user: "user",
    owner: "owner"
  }

  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :user_id, uniqueness: { scope: :workspace_id, message: "is already a member of this workspace" }
end