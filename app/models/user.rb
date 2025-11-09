class User < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: :slugged

    has_secure_password

    has_many :reservations, dependent: :destroy
    has_many :items, through: :reservations
    has_many :user_to_workspaces, dependent: :destroy
    has_many :workspaces, through: :user_to_workspaces

    validates :name, presence: true
    validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
    before_validation :downcase_email

    has_many :owner_joins, -> { where(role: 'owner') }, class_name: 'UserToWorkspace'
    has_many :owned_workspaces, through: :owner_joins, source: :workspace, dependent: :destroy

    has_many :user_joins, -> { where(role: 'user') }, class_name: 'UserToWorkspace'
    has_many :joined_workspaces, through: :user_joins, source: :workspace

    has_many :notifications, dependent: :destroy

    has_many :penalties

    def blocked_from_reserving_in?(workspace)
        penalties.active.any? do |penalty|
            penalty.reservation.item.workspace_id == workspace.id
        end
    end

    def penalty_expiry_for(workspace)
        penalties.active
            .select { |p| p.reservation.item.workspace_id == workspace.id }
            .map(&:expires_at)
            .max
    end

    private

    def downcase_email
        self.email = email.downcase if email.present?
    end

end
