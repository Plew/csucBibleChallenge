class EmailLoginToken < ApplicationRecord
  belongs_to :user
  belongs_to :challenge
  belongs_to :reading

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :unused, -> { where(clicked_at: nil) }
  scope :recent, -> { where("created_at > ?", 7.days.ago) }

  def mark_as_clicked!
    update!(clicked_at: Time.current) unless clicked?
  end

  def clicked?
    clicked_at.present?
  end

  def valid_for_login?
    created_at > 7.days.ago
  end

  private

  def generate_token
    self.token ||= loop do
      random_token = SecureRandom.urlsafe_base64(32)
      break random_token unless EmailLoginToken.exists?(token: random_token)
    end
  end
end
