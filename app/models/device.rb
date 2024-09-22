class Device < ApplicationRecord
  belongs_to :user
end

# == Schema Information
#
# Table name: devices
#
#  id         :integer          not null, primary key
#  device_id  :string
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
