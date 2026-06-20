class Challenge < ApplicationRecord
  belongs_to :creator, class_name: "User"
  has_many :user_challenge_enrollments, dependent: :destroy
  has_many :users, through: :user_challenge_enrollments
  has_many :readings, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :sprints, dependent: :destroy
  has_many :blog_posts, dependent: :destroy
  has_many :user_badges, dependent: :destroy

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), message: "%{value} is not a valid timezone" }
  validates :invitation_token, uniqueness: true, allow_nil: true
  validate :end_date_after_start_date

  before_create :generate_invitation_token

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
