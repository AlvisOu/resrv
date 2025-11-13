class MissingReport < ApplicationRecord
  belongs_to :reservation
  belongs_to :item
  belongs_to :workspace

  validates :reservation, presence: true
  validates :item, presence: true
  validates :workspace, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  after_initialize :set_defaults, if: :new_record?

  scope :unresolved, -> { where(resolved: false) }
  scope :resolved,   -> { where(resolved: true) }

  private

  def set_defaults
    self.resolved = false if self.resolved.nil?
  end
end
