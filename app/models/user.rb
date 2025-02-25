class User < ApplicationRecord
#   validates :name, presence: true
  has_many :devices
  has_many :check_ins
  has_many :group_memberships
  has_many :groups, through: :group_memberships
  has_many :created_groups, class_name: 'Group', foreign_key: 'creator_id'
  before_create :generate_key, :generate_name

  def last_x_check_in_dates(x)
    check_ins.order(recorded_on: :desc).limit(x).pluck(:recorded_on)
  end

  def reset_key
    generate_key
    save!
  end

  private

  def generate_name
    self.name = "Anonymous Reader #{one_to_hundred}" if self.name.blank?
  end

  def one_to_hundred
    (1..100).to_a.sample
  end

  def generate_key
    loop do
      self.key = KeyGenerator.generate
      break unless User.exists?(key: self.key)
    end
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
