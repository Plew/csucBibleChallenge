class User < ApplicationRecord
  validates :name, presence: true
  has_many :devices
  before_create :generate_key

  private

  def generate_key
    self.key = KeyGenerator.generate
  end
end
