class Item < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :workspace

  has_many :reservations, dependent: :destroy
  has_many :users, through: :reservations

  validates :name, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  private

  def end_time_after_start_time
    if start_time.present? && end_time.present? && start_time >= end_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
