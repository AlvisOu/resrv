class Penalty < ApplicationRecord
  belongs_to :user
  belongs_to :workspace
  belongs_to :reservation, optional: true
  has_many :notifications, dependent: :nullify

  VALID_REASONS = ["late_return", "no_show"]
  APPEAL_STATES = ["none", "pending", "resolved"]

  validates :reason, inclusion: { in: VALID_REASONS }
  validates :appeal_state, inclusion: { in: APPEAL_STATES }

  scope :active, -> { where("expires_at > ?", Time.current) }

  def late_return?
    reason == "late_return"
  end

  def no_show?
    reason == "no_show"
  end

  def appeal_pending?
    appeal_state == "pending"
  end

  def appealed?
    appeal_state != "none"
  end
end
