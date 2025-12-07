class Workspace < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: :slugged

    has_many :items, dependent: :destroy
    has_many :user_to_workspaces, dependent: :destroy
    has_many :users, through: :user_to_workspaces
    has_many :missing_reports, dependent: :destroy
    has_many :reservations, through: :items

    validates :name, presence: true

    scope :public_workspaces, -> { where(is_public: true) }

    has_one :owner_join, -> { where(role: 'owner') }, class_name: 'UserToWorkspace'
    has_one :owner, through: :owner_join, source: :user
end
