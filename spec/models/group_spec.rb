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

    it { should allow_value(nil, "", "US", "DE").for(:country_code) }
    it { should_not allow_value("ZZ", "XX").for(:country_code) }
  end

  describe '#country' do
    it 'returns the ISO3166::Country when country_code is set' do
      group = FactoryBot.build(:group, country_code: "DE")
      expect(group.country).to be_a(ISO3166::Country)
      expect(group.country.alpha2).to eq("DE")
    end

    it 'returns nil when country_code is blank' do
      group = FactoryBot.build(:group, country_code: nil)
      expect(group.country).to be_nil
    end
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

  describe '#transfer_ownership_to_first_joined!' do
    let(:creator) { create(:user) }
    let(:group) { create(:group, creator: creator) }
    let(:member1) { create(:user) }
    let(:member2) { create(:user) }

    before do
      create(:user_group_enrollment, user: creator, group: group, created_at: 10.days.ago)
      create(:user_group_enrollment, user: member1, group: group, created_at: 5.days.ago)
      create(:user_group_enrollment, user: member2, group: group, created_at: 2.days.ago)
    end

    it 'transfers ownership to the member who joined earliest' do
      new_owner = group.transfer_ownership_to_first_joined!(excluding: creator)
      expect(new_owner).to eq(member1)
      expect(group.reload.creator).to eq(member1)
    end

    it 'returns nil and does not change creator if no other members exist' do
      only_creator_group = create(:group, creator: creator)
      create(:user_group_enrollment, user: creator, group: only_creator_group)

      new_owner = only_creator_group.transfer_ownership_to_first_joined!(excluding: creator)
      expect(new_owner).to be_nil
      expect(only_creator_group.reload.creator).to eq(creator)
    end
  end

  it 'is valid with valid attributes' do
    expect(FactoryBot.build(:group)).to be_valid
  end
end
