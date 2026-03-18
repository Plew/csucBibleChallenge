require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:user_group_enrollments).dependent(:destroy) }
    it { should have_many(:users).through(:user_group_enrollments) }
    it { should have_many(:sprint_winners).dependent(:destroy) }
    it { should have_many(:won_sprints).through(:sprint_winners) }
  end

  describe 'destroying a group that is a sprint winner' do
    it 'destroys associated sprint_winners records' do
      group = create(:group)
      challenge = group.challenge
      sprint = create(:sprint, challenge: challenge,
                      begin_date: challenge.start_date, end_date: challenge.end_date)
      create(:sprint_winner, sprint: sprint, group: group)

      expect { group.destroy }.to change(SprintWinner, :count).by(-1)
    end
  end

  describe 'validations' do
    subject { FactoryBot.create(:group) } # Create for uniqueness check

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:challenge_id).with_message("name should be unique within the challenge") }
  end

  describe 'attributes' do
    it 'has closed_to_new_members defaulting to false' do
      group = FactoryBot.create(:group)
      expect(group.closed_to_new_members).to eq(false)
    end

    it 'can be set to closed_to_new_members' do
      group = FactoryBot.create(:group, closed_to_new_members: true)
      expect(group.closed_to_new_members).to eq(true)
    end
  end

  it 'is valid with valid attributes' do
    expect(FactoryBot.build(:group)).to be_valid
  end
end
