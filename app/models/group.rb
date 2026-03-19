class Group < ApplicationRecord
  belongs_to :challenge
  belongs_to :creator, class_name: "User"
  has_many :user_group_enrollments, dependent: :destroy
  has_many :users, through: :user_group_enrollments
  has_many :group_messages, dependent: :destroy
  has_many :sprint_winners, dependent: :nullify
  has_many :won_sprints, through: :sprint_winners, source: :sprint
  # If you want to directly get users in a group: has_many :users, through: :user_challenge_enrollments, source: :user

  validates :name, presence: true,
                   uniqueness: { scope: :challenge_id, message: "name should be unique within the challenge" }
  validates :creator, presence: true
  validates :token, uniqueness: true, allow_nil: true

  before_create :generate_token

  def generate_token
    loop do
      self.token = SecureRandom.alphanumeric(6)
      break unless Group.exists?(token: token)
    end
  end

  def regenerate_token!
    generate_token
    save!
  end

  def join_url
    Rails.application.routes.url_helpers.group_invitation_url(token, host: ENV.fetch("APP_HOST", "localhost:3000"))
  end
end
