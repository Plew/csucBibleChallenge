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

  attr_accessor :current_password, :skip_current_password_validation

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :version, inclusion: { in: %w[ASV ELB2006 ESV KJV NASB NKJV], message: "must be a valid Bible version" }
  validates :current_password, presence: true, if: :password_being_updated_and_not_resetting?
  validate :current_password_correct, if: :password_being_updated_and_not_resetting?

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

  def admin?
    admin
  end

  private

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
      errors.add(:current_password, 'is incorrect')
    end
  end
end
