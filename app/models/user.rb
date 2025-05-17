class User < ApplicationRecord
  has_secure_password
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
    attachable.variant :medium, resize_to_limit: [300, 300]
  end

  has_many :user_challenge_enrollments, dependent: :destroy
  has_many :challenges, through: :user_challenge_enrollments
  has_many :user_readings, dependent: :destroy
  has_many :completed_readings, through: :user_readings, source: :reading
  has_many :user_group_enrollments, dependent: :destroy
  has_many :groups, through: :user_group_enrollments

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
end
