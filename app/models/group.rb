class Group < ApplicationRecord
  belongs_to :challenge
  belongs_to :creator, class_name: 'User'
  has_many :user_group_enrollments, dependent: :destroy
  has_many :users, through: :user_group_enrollments
  has_many :group_messages, dependent: :destroy
  # If you want to directly get users in a group: has_many :users, through: :user_challenge_enrollments, source: :user

  validates :name, presence: true,
                   uniqueness: { scope: :challenge_id, message: "name should be unique within the challenge" }
  validates :creator, presence: true
end
