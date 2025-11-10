class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :reservation

  scope :unread, -> { where(read: false) }
end
