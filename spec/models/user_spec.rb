require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#generate_key' do
    it 'generates a key before creating a user' do
      user = FactoryBot.build(:user)
      
      allow(KeyGenerator).to receive(:generate).and_return('generated_key')
      user.save
      
      expect(user.key).to eq('generated_key')
      expect(KeyGenerator).to have_received(:generate)
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
