class MissingReport < ApplicationRecord
  belongs_to :reservation
  belongs_to :item
  belongs_to :workspace

  scope :unresolved, -> { where(resolved: false) }
  scope :resolved,   -> { where(resolved: true) }
end
