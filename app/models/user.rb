class User < ApplicationRecord
#   validates :name, presence: true
  has_many :devices
  has_many :check_ins
  before_create :generate_key

  def last_x_check_in_dates(x)
    check_ins.order(recorded_on: :desc).limit(x).pluck(:recorded_on)
  end

  private

  def generate_key
    self.key = KeyGenerator.generate
  end
end

# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
