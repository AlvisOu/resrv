class User < ApplicationRecord
    has_secure_password

    has_many :reservations, dependent: :destroy
    has_many :items, through: :reservations
    has_many :user_to_workspaces, dependent: :destroy
    has_many :workspaces, through: :user_to_workspaces

    validates :name, presence: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
end
