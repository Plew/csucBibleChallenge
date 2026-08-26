class Challenge < ApplicationRecord
  belongs_to :creator, class_name: "User"
  has_many :user_challenge_enrollments, dependent: :destroy
  has_many :users, through: :user_challenge_enrollments
  has_many :readings, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :sprints, dependent: :destroy
  has_many :blog_posts, dependent: :destroy
  has_many :user_badges, dependent: :destroy

  serialize :skip_days_of_week, coder: JSON
  serialize :skip_dates, coder: JSON

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), message: "%{value} is not a valid timezone" }
  validates :invitation_token, uniqueness: true, allow_nil: true
  validates :chapters_per_day, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 50 }, allow_nil: true
  validate :end_date_after_start_date

  before_create :generate_invitation_token

  def skip_days_of_week_list
    Array(skip_days_of_week).map(&:to_i)
  end

  def skip_dates_list
    (skip_dates || []).map do |d|
      d.is_a?(Date) ? d : (Date.parse(d.to_s) rescue nil)
    end.compact
  end

  def reading_days_of_week_list
    all_days = [1, 2, 3, 4, 5, 6, 0] # Mon(1)..Sat(6), Sun(0)
    all_days - skip_days_of_week_list
  end

  def daily_reading_status(user)
    return { has_reading: false, read_today: false, read_count: 0, total_count: 0, reading_title: nil, today_date: Date.current } unless user

    today_in_tz = Time.current.in_time_zone(timezone).to_date
    today_readings = readings.where(scheduled_date: today_in_tz).order(:book_number, :chapter_number)

    if today_readings.any?
      completed_ids = user.user_readings.where(reading_id: today_readings.pluck(:id)).pluck(:reading_id)
      read_count = completed_ids.size
      read_today = (read_count == today_readings.size)
      first_reading = today_readings.first
      book_name = ApplicationController.helpers.book_number_to_name(first_reading.book_number)
      reading_name = if today_readings.size == 1
                       "#{book_name} #{first_reading.chapter_number}"
                     else
                       "#{today_readings.size} chapters"
                     end

      {
        has_reading: true,
        read_today: read_today,
        read_count: read_count,
        total_count: today_readings.size,
        reading_title: reading_name,
        today_date: today_in_tz
      }
    else
      {
        has_reading: false,
        read_today: false,
        read_count: 0,
        total_count: 0,
        reading_title: nil,
        today_date: today_in_tz
      }
    end
  end

  def reading_day?(date)
    return false if date.blank? || start_date.blank? || end_date.blank?
    return false if date < start_date || date > end_date

    d = date.to_date
    return false if skip_days_of_week_list.include?(d.wday)
    return false if skip_dates_list.include?(d)

    true
  end

  scope :active, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :past, -> { where("end_date < ?", Date.current) }

  def in_progress?
    start_date <= Date.current && end_date >= Date.current
  end

  def past?
    end_date < Date.current
  end

  alias_attribute :title, :name

  def generate_invitation_token
    loop do
      self.invitation_token = SecureRandom.alphanumeric(6)
      break unless Challenge.exists?(invitation_token: invitation_token)
    end
  end

  def regenerate_invitation_token!
    generate_invitation_token
    save!
  end

  # Read-only API key used by challenge organizers to query challenge data via
  # the Api::V1::ChallengeReportsController. Generated on demand (nil until then).
  def self.generate_api_key
    "andgodsaid_#{SecureRandom.urlsafe_base64(32)}"
  end

  def regenerate_api_key!
    update!(api_key: self.class.generate_api_key)
  end

  def owned_by?(user)
    user.present? && creator_id == user.id
  end

  def challenge_organizer?(user)
    return false unless user.present?

    user_challenge_enrollments.exists?(user: user, role: "organizer")
  end

  def manageable_by?(user)
    return false unless user.present?
    user.admin? || owned_by?(user) || challenge_organizer?(user)
  end

  def owner_or_site_admin?(user)
    return false unless user.present?
    owned_by?(user) || user.admin?
  end

  def join_url
    Rails.application.routes.url_helpers.challenge_invitation_url(invitation_token, host: ENV.fetch("APP_HOST", "localhost:3000"))
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be on or after the start date")
    end
  end
end
