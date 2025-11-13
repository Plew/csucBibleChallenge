class StatWindow < ApplicationRecord
  belongs_to :challenge

  validates :title, presence: true
  validates :begin_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_begin_date
  validate :dates_within_challenge_range

  scope :for_challenge, ->(challenge_id) { where(challenge_id: challenge_id) }
  scope :ordered, -> { order(begin_date: :asc) }

  def date_range
    begin_date..end_date
  end

  private

  def end_date_after_begin_date
    return if end_date.blank? || begin_date.blank?

    if end_date < begin_date
      errors.add(:end_date, "must be on or after the begin date")
    end
  end

  def dates_within_challenge_range
    return if challenge.blank? || begin_date.blank? || end_date.blank?

    if begin_date < challenge.start_date
      errors.add(:begin_date, "must be on or after the challenge start date (#{challenge.start_date})")
    end

    if end_date > challenge.end_date
      errors.add(:end_date, "must be on or before the challenge end date (#{challenge.end_date})")
    end
  end
end
