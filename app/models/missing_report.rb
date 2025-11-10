class MissingReport < ApplicationRecord
  belongs_to :reservation
  belongs_to :item
  belongs_to :workspace
  
  scope :unresolved, -> { where(status: "unresolved") }
  scope :resolved,   -> { where(status: "resolved") }
end
