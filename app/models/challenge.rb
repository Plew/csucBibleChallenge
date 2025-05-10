class Challenge < ApplicationRecord
  has_many :user_challenge_enrollments, dependent: :destroy
  has_many :users, through: :user_challenge_enrollments
  has_many :readings, dependent: :destroy

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be on or after the start date")
    end
  end
end
