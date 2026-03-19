require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:user_group_enrollments).dependent(:destroy) }
    it { should have_many(:users).through(:user_group_enrollments) }
    it { should have_many(:sprint_winners).dependent(:nullify) }
    it { should have_many(:won_sprints).through(:sprint_winners) }
  end

  describe 'destroying a group that is a sprint winner' do
    it 'nullifies the group_id on associated sprint_winners records' do
      group = create(:group)
      challenge = group.challenge
      sprint = create(:sprint, challenge: challenge,
                      begin_date: challenge.start_date, end_date: challenge.end_date)
      winner = create(:sprint_winner, sprint: sprint, group: group, group_name: group.name)

      expect { group.destroy }.not_to change(SprintWinner, :count)
      expect(winner.reload.group_id).to be_nil
      expect(winner.group_name).to eq(group.name)
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
