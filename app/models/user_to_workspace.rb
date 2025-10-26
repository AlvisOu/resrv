class UserToWorkspace < ApplicationRecord
  ALLOWED_ROLES = %w[user owner].freeze

  belongs_to :user
  belongs_to :workspace

  validates :role, presence: true, inclusion: { in: ALLOWED_ROLES }
  validates :user_id, uniqueness: { scope: :workspace_id, message: "is already a member of this workspace" }

  def owner?
    role == 'owner'
  end
  
  def user?
    role == 'user'
  end

end