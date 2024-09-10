class User < ApplicationRecord
#   validates :name, presence: true
  has_many :devices
  has_many :check_ins
  before_create :generate_key

  private

  def generate_key
    self.key = KeyGenerator.generate
  end
end
