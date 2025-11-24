class User < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: :slugged

    has_secure_password

    has_many :reservations, dependent: :destroy
    has_many :items, through: :reservations
    has_many :user_to_workspaces, dependent: :destroy
    has_many :workspaces, through: :user_to_workspaces

    has_many :owner_joins, -> { where(role: 'owner') }, class_name: 'UserToWorkspace'
    has_many :owned_workspaces, through: :owner_joins, source: :workspace, dependent: :destroy

    has_many :user_joins, -> { where(role: 'user') }, class_name: 'UserToWorkspace'
    has_many :joined_workspaces, through: :user_joins, source: :workspace

    has_many :notifications, dependent: :destroy
    has_many :penalties

    validates :name, presence: true
    validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
    before_validation :downcase_email

    def send_password_reset_email
        self.reset_token = SecureRandom.urlsafe_base64
        self.reset_sent_at = Time.now
        if save!
          UserMailer.send_password_reset(self).deliver_now
        end
    end

    def reset_password(new_password, new_password_confirmation)
        if reset_sent_at < 15.minutes.ago
            self.errors.add(:reset_token, "has expired")
            return false
        end

        if update(password: new_password, password_confirmation: new_password_confirmation)
            update(reset_token: nil, reset_sent_at: nil)
            return true
        else
            return false
        end
    end

    def send_verification_email
        self.verification_code = SecureRandom.random_number(100000..999999).to_s
        self.verification_sent_at = Time.now
        save!
        UserMailer.send_verification_code(self).deliver_now
    end

    def verify_email_code(submitted_code)
        return false if verification_code != submitted_code
        return false if verification_sent_at < 10.minutes.ago
        self.email_verified_at = Time.now
        self.verification_code = nil
        save!
    end

    def verified?
        email_verified_at.present?
    end

    def blocked_from_reserving_in?(workspace)
        penalties.active.any? do |penalty|
            penalty_workspace_id(penalty) == workspace.id
        end
    end

    def penalty_expiry_for(workspace)
        penalties.active
            .select { |p| penalty_workspace_id(p) == workspace.id }
            .map(&:expires_at)
            .max
    end

    private

    def downcase_email
        self.email = email.downcase if email.present?
    end

    def penalty_workspace_id(penalty)
        penalty.workspace_id || penalty.reservation&.item&.workspace_id
    end
end
