require 'rails_helper'

RSpec.describe PieDataFromGroupDay do
  describe '#pie_chart_data' do
    let(:group) { create(:group) }
    let(:day) { Date.current }
    let(:service) { described_class.new(group, day) }
    
    context 'when there are users in the group' do
      let!(:user1) { create(:user, name: 'User 1') }
      let!(:user2) { create(:user, name: 'User 2') }
      let!(:user3) { create(:user, name: 'User 3') } # Anonymous user
      
      before do
        create(:group_membership, group: group, user: user1)
        create(:group_membership, group: group, user: user2)
        create(:group_membership, group: group, user: user3)
        
        # Create check-ins for some users
        create(:check_in, user: user1, recorded_on: day)
        create(:check_in, user: user3, recorded_on: day)
        # User2 doesn't check in
      end
      
      it 'returns pie chart data with correct structure' do
        result = service.pie_chart_data
        
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        
        expect(result).to include(
          { name: 'User 1', checked_in_value: 1 },
          { name: 'User 3', checked_in_value: 1 },
          { name: 'User 2', checked_in_value: 0 }
        )
      end
      
      it 'orders results with checked-in users first' do
        result = service.pie_chart_data
        
        # First entries should have checked_in_value of 1
        expect(result[0][:checked_in_value]).to eq(1)
        expect(result[1][:checked_in_value]).to eq(1)
        expect(result[2][:checked_in_value]).to eq(0)
      end
    end
    
    context 'when there are no users in the group' do
      it 'returns an empty array' do
        expect(service.pie_chart_data).to eq([])
      end
    end
    
    context 'when users have check-ins on different days' do
      let!(:user) { create(:user, name: 'User') }
      let(:yesterday) { day - 1.day }
      
      before do
        create(:group_membership, group: group, user: user)
        create(:check_in, user: user, recorded_on: yesterday) # Check-in on a different day
      end
      
      it 'only counts check-ins for the specified day' do
        result = service.pie_chart_data
        
        expect(result.size).to eq(1)
        expect(result.first).to eq({ name: 'User', checked_in_value: 0 })
      end
    end
  end
end 