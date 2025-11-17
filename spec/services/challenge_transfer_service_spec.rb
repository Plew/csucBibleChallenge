require 'rails_helper'

RSpec.describe ChallengeTransferService do
  let!(:from_challenge) { create(:challenge, name: 'Old Challenge') }
  let!(:to_challenge) { create(:challenge, name: 'New Challenge') }

  describe '#call' do
    context 'when transferring to the same challenge' do
      subject(:service) { described_class.new(from_challenge, from_challenge) }

      it 'returns false' do
        expect(service.call).to be false
      end

      it 'adds an error message' do
        service.call
        expect(service.errors).to include('Cannot transfer to the same challenge')
      end
    end

    context 'when transferring users without groups' do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }
      let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: from_challenge) }
      let!(:enrollment2) { create(:user_challenge_enrollment, user: user2, challenge: from_challenge) }

      subject(:service) { described_class.new(from_challenge, to_challenge) }

      it 'returns true' do
        expect(service.call).to be true
      end

      it 'transfers users to the new challenge' do
        expect { service.call }.to change { to_challenge.users.count }.from(0).to(2)
        expect(from_challenge.reload.users.count).to eq(0)
      end

      it 'updates transferred_count' do
        service.call
        expect(service.transferred_count).to eq(2)
      end

      it 'has no errors' do
        service.call
        expect(service.errors).to be_empty
      end
    end

    context 'when transferring users with groups' do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }
      let!(:user3) { create(:user) }
      let!(:group_creator) { create(:user) }

      let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: from_challenge) }
      let!(:enrollment2) { create(:user_challenge_enrollment, user: user2, challenge: from_challenge) }
      let!(:enrollment3) { create(:user_challenge_enrollment, user: user3, challenge: from_challenge) }
      let!(:creator_enrollment) { create(:user_challenge_enrollment, user: group_creator, challenge: from_challenge) }

      let!(:group1) { create(:group, name: 'Team Alpha', challenge: from_challenge, creator: group_creator) }
      let!(:group2) { create(:group, name: 'Team Beta', challenge: from_challenge, creator: group_creator) }

      let!(:group_enrollment1) { create(:user_group_enrollment, user: user1, group: group1) }
      let!(:group_enrollment2) { create(:user_group_enrollment, user: user2, group: group1) }
      let!(:group_enrollment3) { create(:user_group_enrollment, user: user3, group: group2) }
      let!(:creator_group_enrollment) { create(:user_group_enrollment, user: group_creator, group: group1) }

      subject(:service) { described_class.new(from_challenge, to_challenge) }

      it 'duplicates groups to the new challenge' do
        expect { service.call }.to change { to_challenge.groups.count }.from(0).to(2)

        new_group1 = to_challenge.groups.find_by(name: 'Team Alpha')
        new_group2 = to_challenge.groups.find_by(name: 'Team Beta')

        expect(new_group1).to be_present
        expect(new_group2).to be_present
        expect(new_group1.creator).to eq(group_creator)
        expect(new_group2.creator).to eq(group_creator)
      end

      it 'transfers user group memberships to duplicated groups' do
        service.call

        new_group1 = to_challenge.groups.find_by(name: 'Team Alpha')
        new_group2 = to_challenge.groups.find_by(name: 'Team Beta')

        expect(new_group1.users).to match_array([user1, user2, group_creator])
        expect(new_group2.users).to match_array([user3])
      end

      it 'leaves old groups in the source challenge' do
        expect { service.call }.not_to change { from_challenge.reload.groups.count }
        expect(from_challenge.groups.count).to eq(2)
      end

      it 'removes old group memberships' do
        service.call

        # Users should no longer be in the old groups
        expect(user1.reload.groups).not_to include(group1)
        expect(user2.reload.groups).not_to include(group1)
        expect(user3.reload.groups).not_to include(group2)
      end

      it 'updates groups_duplicated count' do
        service.call
        expect(service.groups_duplicated).to eq(2)
      end

      it 'updates transferred_count' do
        service.call
        expect(service.transferred_count).to eq(4)
      end
    end

    context 'when a user is already enrolled in the target challenge' do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }

      let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: from_challenge) }
      let!(:enrollment2) { create(:user_challenge_enrollment, user: user2, challenge: from_challenge) }
      let!(:existing_enrollment) { create(:user_challenge_enrollment, user: user1, challenge: to_challenge) }

      subject(:service) { described_class.new(from_challenge, to_challenge) }

      it 'skips the already enrolled user' do
        service.call
        expect(to_challenge.users).to match_array([user1, user2])
        expect(from_challenge.reload.users).to be_empty
      end

      it 'updates skipped_count' do
        service.call
        expect(service.skipped_count).to eq(1)
      end

      it 'updates transferred_count correctly' do
        service.call
        expect(service.transferred_count).to eq(1)
      end
    end

    context 'when a group with the same name exists in the target challenge' do
      let!(:user1) { create(:user) }
      let!(:group_creator) { create(:user) }

      let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: from_challenge) }
      let!(:creator_enrollment) { create(:user_challenge_enrollment, user: group_creator, challenge: from_challenge) }

      let!(:from_group) { create(:group, name: 'Existing Group', challenge: from_challenge, creator: group_creator) }
      let!(:to_group) { create(:group, name: 'Existing Group', challenge: to_challenge, creator: group_creator) }

      let!(:group_enrollment) { create(:user_group_enrollment, user: user1, group: from_group) }

      subject(:service) { described_class.new(from_challenge, to_challenge) }

      it 'uses the existing group instead of creating a duplicate' do
        expect { service.call }.not_to change { to_challenge.groups.count }
        expect(to_group.reload.users).to include(user1)
      end

      it 'does not increment groups_duplicated count' do
        service.call
        expect(service.groups_duplicated).to eq(0)
      end
    end

    context 'when users are in multiple groups' do
      let!(:user1) { create(:user) }
      let!(:group_creator) { create(:user) }

      let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: from_challenge) }
      let!(:creator_enrollment) { create(:user_challenge_enrollment, user: group_creator, challenge: from_challenge) }

      let!(:group1) { create(:group, name: 'Group 1', challenge: from_challenge, creator: group_creator) }
      let!(:group2) { create(:group, name: 'Group 2', challenge: from_challenge, creator: group_creator) }

      let!(:group_enrollment1) { create(:user_group_enrollment, user: user1, group: group1) }
      let!(:group_enrollment2) { create(:user_group_enrollment, user: user1, group: group2) }

      subject(:service) { described_class.new(from_challenge, to_challenge) }

      it 'maintains all group memberships in the new challenge' do
        service.call

        new_group1 = to_challenge.groups.find_by(name: 'Group 1')
        new_group2 = to_challenge.groups.find_by(name: 'Group 2')

        expect(user1.reload.groups).to match_array([new_group1, new_group2])
      end
    end
  end

  describe '#success_message' do
    let!(:user1) { create(:user) }
    let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: from_challenge) }

    subject(:service) { described_class.new(from_challenge, to_challenge) }

    it 'returns a formatted success message' do
      service.call
      message = service.success_message
      expect(message).to include('Successfully transferred 1 users')
      expect(message).to include('duplicated 0 groups')
      expect(message).to include('0 users were already enrolled')
    end
  end

  describe '#error_message' do
    let!(:user1) { create(:user) }
    let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: from_challenge) }

    subject(:service) { described_class.new(from_challenge, to_challenge) }

    before do
      service.call
      service.instance_variable_set(:@errors, ['Test error'])
    end

    it 'returns a formatted error message' do
      message = service.error_message
      expect(message).to include('Transfer completed with errors')
      expect(message).to include('Test error')
    end
  end
end
