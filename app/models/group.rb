class Group < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id', required: true
  has_many :group_memberships
  has_many :users, through: :group_memberships
  validates :name, presence: true

  before_create :generate_key

  def reset_key
    generate_key
    save!
  end

  private

  def generate_key
    loop do
      self.key = KeyGenerator.generate
      break unless User.exists?(key: self.key)
    end
  end
end