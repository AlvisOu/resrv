class Item < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :workspace

  has_many :reservations, dependent: :destroy
  has_many :users, through: :reservations

  has_many :missing_reports, dependent: :destroy

  validates :name, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :start_time, presence: true
  validates :end_time, presence: true

  include TimeValidatable
  validate :end_time_after_start_time
end
