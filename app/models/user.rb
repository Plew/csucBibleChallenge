class User < ApplicationRecord
  has_secure_password

  has_many :user_challenge_enrollments, dependent: :destroy
  has_many :challenges, through: :user_challenge_enrollments
  has_many :user_readings, dependent: :destroy
  has_many :completed_readings, through: :user_readings, source: :reading

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
end
