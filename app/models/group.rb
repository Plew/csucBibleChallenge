class Group < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id', required: true
  validates :name, presence: true
end
