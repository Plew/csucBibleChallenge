class Group < ApplicationRecord
  belongs_to :challenge
  has_many :user_challenge_enrollments, dependent: :nullify # Or :destroy if enrollments should be deleted with group
  has_many :users, through: :user_challenge_enrollments, source: :user
  # If you want to directly get users in a group: has_many :users, through: :user_challenge_enrollments, source: :user

  validates :name, presence: true,
                   uniqueness: { scope: :challenge_id, message: "name should be unique within the challenge" }
end
