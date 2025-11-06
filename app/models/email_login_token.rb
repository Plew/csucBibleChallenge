class EmailLoginToken < ApplicationRecord
  belongs_to :user
  belongs_to :challenge
  belongs_to :reading

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :unused, -> { where(clicked_at: nil) }
  scope :recent, -> { where("created_at > ?", 24.hours.ago) }

  def mark_as_clicked!
    update!(clicked_at: Time.current)
  end

  def clicked?
    clicked_at.present?
  end

  def valid_for_login?
    # Token is valid if it was created within last 24 hours and hasn't been clicked
    created_at > 24.hours.ago && !clicked?
  end

  private

  def generate_token
    self.token ||= loop do
      random_token = SecureRandom.urlsafe_base64(32)
      break random_token unless EmailLoginToken.exists?(token: random_token)
    end
  end
end
