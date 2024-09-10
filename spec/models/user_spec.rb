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
