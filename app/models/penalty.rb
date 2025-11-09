class Penalty < ApplicationRecord
  belongs_to :user
  belongs_to :workspace
  belongs_to :reservation, optional: true

  VALID_REASONS = ["late_return", "no_show"]

  validates :reason, inclusion: { in: VALID_REASONS }

  scope :active, -> { where("expires_at > ?", Time.current) }

  def late_return?
    reason == "late_return"
  end

  def no_show?
    reason == "no_show"
  end
end
