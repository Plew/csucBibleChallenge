class User < ApplicationRecord
  VALID_VERSIONS = [ "ASV", "ELB2006", "ESV", "KJV", "NASB", "NKJV", "RCV", "SCHL2000" ].freeze

  # Challenge #9 ("And God Said Bible Challenge (NT)") is pinned to its original end date
  # so that readings added after the cutoff never change who counts as 100%
  # complete. Used by the Manage users completion filter (see
  # Manage::UsersController#completion_cutoff_date).
  BANQUET_CHALLENGE_ID = 9
  BANQUET_CUTOFF_DATE = Date.new(2026, 7, 3)

  has_secure_password
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 48, 48 ], preprocessed: true     # 24x24 display * 2 for retina
    attachable.variant :medium, resize_to_fill: [ 72, 72 ], preprocessed: true    # 36x36 display * 2 for retina
    attachable.variant :large, resize_to_fill: [ 96, 96 ], preprocessed: true     # 48x48 display * 2 for retina
    attachable.variant :xlarge, resize_to_fill: [ 128, 128 ], preprocessed: true  # 64x64 display * 2 for retina
    attachable.variant :xxlarge, resize_to_fill: [ 192, 192 ], preprocessed: true # 96x96 display * 2 for retina
    attachable.variant :profile, resize_to_fill: [ 500, 500 ], preprocessed: true # For profile pages, modals, etc.
  end

  has_many :user_challenge_enrollments, dependent: :destroy
  has_many :challenges, through: :user_challenge_enrollments
  has_many :created_challenges, class_name: "Challenge", foreign_key: :creator_id, dependent: :destroy
  has_many :user_readings, dependent: :destroy
  has_many :completed_readings, through: :user_readings, source: :reading
  has_many :user_group_enrollments, dependent: :destroy
  has_many :groups, through: :user_group_enrollments
  has_many :created_groups, class_name: "Group", foreign_key: :creator_id, dependent: :destroy
  has_many :blog_posts, dependent: :destroy
  has_many :blog_comments, dependent: :destroy
  has_many :verse_likes, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :sent_pokes, class_name: "Poke", foreign_key: :poker_id, dependent: :destroy
  has_many :received_pokes, class_name: "Poke", foreign_key: :pokee_id, dependent: :destroy

  attr_accessor :current_password, :skip_current_password_validation

  after_initialize :set_default_version, if: :new_record?

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :version, inclusion: { in: VALID_VERSIONS, message: "must be a valid Bible version" }
  validates :daily_email_hour, inclusion: { in: 0..23, message: "must be between 0 and 23" }, allow_nil: true
  validate :avatar_content_type_allowed
  validates :current_password, presence: true, if: :password_being_updated_and_not_resetting?
  validate :current_password_correct, if: :password_being_updated_and_not_resetting?

  def set_default_version
    self.version ||= "ESV"
    self.daily_email_hour ||= 6
  end

  scope :wants_daily_email, -> { where(daily_email: true) }

  alias_attribute :name, :username

  def create_reset_digest
    token = SecureRandom.urlsafe_base64
    self.reset_digest = token
    self.password_reset_sent_at = Time.current
    save!(validate: false)
    token
  end

  def password_reset_valid?
    password_reset_sent_at && password_reset_sent_at > 2.hours.ago
  end

  def create_unsubscribe_digest
    token = SecureRandom.urlsafe_base64
    self.unsubscribe_digest = token
    self.unsubscribe_sent_at = Time.current
    save!(validate: false)
    token
  end

  def unsubscribe_token_valid?
    !!(unsubscribe_sent_at && unsubscribe_sent_at > 24.hours.ago)
  end

  def admin?
    admin
  end

  def can_create_challenges?
    true
  end

  # Resolves the single "active" challenge for single-challenge UI surfaces (reading
  # page, bottom nav, etc.) per the CONTEXT.md definition:
  #   1. In-progress today (start_date <= today <= end_date), most-recently-joined first.
  #   2. If none in progress, most-recently-joined overall.
  def active_challenge
    today = Date.current
    by_recency = user_challenge_enrollments.includes(:challenge).order(created_at: :desc)
    in_progress = by_recency.select { |e| e.challenge.start_date <= today && e.challenge.end_date >= today }
    return in_progress.first&.challenge if in_progress.any?
    by_recency.first&.challenge
  end

  # Challenges this user directly manages (as creator or challenge organizer).
  # Does not expand to all challenges for global admins — they access others via /admin.
  def directly_managed_challenges
    created_ids = created_challenges.pluck(:id)
    organizer_ids = user_challenge_enrollments.where(role: "organizer").pluck(:challenge_id)
    Challenge.where(id: (created_ids + organizer_ids).uniq).order(:name)
  end

  private

  ALLOWED_AVATAR_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze

  def avatar_content_type_allowed
    return unless avatar.attached?
    unless ALLOWED_AVATAR_TYPES.include?(avatar.blob.content_type)
      errors.add(:avatar, "must be a PNG, JPEG, GIF, or WebP image")
    end
  end

  def password_being_updated?
    !new_record? && password.present?
  end

  def password_being_updated_and_not_resetting?
    password_being_updated? && !skip_current_password_validation
  end

  def current_password_correct
    return if current_password.blank?

    # Get the original password_digest to authenticate against
    original_user = User.find(self.id)
    unless original_user.authenticate(current_password)
      errors.add(:current_password, "is incorrect")
    end
  end
end
