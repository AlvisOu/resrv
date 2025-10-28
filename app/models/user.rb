class User < ApplicationRecord
    has_secure_password

    validates :password, confirmation: true, if: -> { password.present? }

    has_many :reservations, dependent: :destroy
    has_many :items, through: :reservations
    has_many :user_to_workspaces, dependent: :destroy
    has_many :workspaces, through: :user_to_workspaces

    validates :name, presence: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

    has_many :owner_joins, -> { where(role: 'owner') }, class_name: 'UserToWorkspace'
    has_many :owned_workspaces, through: :owner_joins, source: :workspace, dependent: :destroy

    has_many :user_joins, -> { where(role: 'user') }, class_name: 'UserToWorkspace'
    has_many :joined_workspaces, through: :user_joins, source: :workspace
end
