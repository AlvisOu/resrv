class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :reservation, optional: true

  validates :user, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read: false) }

  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.read = false if read.nil?
  end
end
