class Sprint < ApplicationRecord
  belongs_to :challenge

  validates :title, presence: true
  validates :begin_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_begin_date
  validate :dates_within_challenge_range
  validate :no_overlapping_dates

  scope :for_challenge, ->(challenge_id) { where(challenge_id: challenge_id) }
  scope :ordered, -> { order(begin_date: :asc) }
  scope :active, -> { where("begin_date <= ? AND end_date >= ?", Date.current, Date.current) }

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

  def no_overlapping_dates
    return if challenge.blank? || begin_date.blank? || end_date.blank?

    overlapping_sprints = challenge.sprints
      .where.not(id: id) # Exclude current record when updating
      .where("(begin_date <= ? AND end_date >= ?) OR (begin_date <= ? AND end_date >= ?) OR (begin_date >= ? AND end_date <= ?)",
        end_date, begin_date,    # New sprint's end overlaps existing sprint's range
        begin_date, end_date,    # New sprint's begin overlaps existing sprint's range
        begin_date, end_date)    # New sprint completely contains existing sprint

    if overlapping_sprints.exists?
      errors.add(:base, "Sprint dates overlap with existing sprint in this challenge")
    end
  end
end
