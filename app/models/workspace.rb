class Workspace < ApplicationRecord
    has_many :items, dependent: :destroy
    has_many :user_to_workspaces, dependent: :destroy
    has_many :users, through: :user_to_workspaces

    validates :name, presence: true
    validates :location, presence: true
end
