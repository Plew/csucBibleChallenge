require 'rails_helper'

RSpec.describe RemoveInactiveUsersFromGroupsJob, type: :job do
  let(:owner) { create(:user) }

  describe "#perform" do
    context "when challenge has auto_remove_inactive_from_groups enabled" do
      let(:challenge) { create(:challenge, creator: owner, auto_remove_inactive_from_groups: true) }
      let(:group) { create(:group, challenge: challenge, creator: owner) }
      let(:active_user) { create(:user) }
      let(:inactive_user) { create(:user) }

      before do
        create(:user_challenge_enrollment, user: active_user, challenge: challenge)
        create(:user_challenge_enrollment, user: inactive_user, challenge: challenge)
        create(:user_group_enrollment, user: active_user, group: group)
        create(:user_group_enrollment, user: inactive_user, group: group)
      end

      it "removes inactive users from their group" do
        reading = create(:reading, challenge: challenge, scheduled_date: 5.days.ago)
        create(:user_reading, user: active_user, reading: reading, completed_on: 5.days.ago)
        # inactive_user has no readings

        expect {
          described_class.perform_now
        }.to change { UserGroupEnrollment.where(user: inactive_user).count }.by(-1)
      end

      it "keeps active users in their group" do
        reading = create(:reading, challenge: challenge, scheduled_date: 5.days.ago)
        create(:user_reading, user: active_user, reading: reading, completed_on: 5.days.ago)

        expect {
          described_class.perform_now
        }.not_to change { UserGroupEnrollment.where(user: active_user).count }
      end

      it "does NOT remove inactive users from the challenge" do
        expect {
          described_class.perform_now
        }.not_to change(UserChallengeEnrollment, :count)
      end

      it "considers activity within the last 10 days as active" do
        reading = create(:reading, challenge: challenge, scheduled_date: 9.days.ago)
        create(:user_reading, user: inactive_user, reading: reading, completed_on: 9.days.ago)

        expect {
          described_class.perform_now
        }.not_to change { UserGroupEnrollment.where(user: inactive_user).count }
      end

      it "considers activity older than 10 days as inactive" do
        reading = create(:reading, challenge: challenge, scheduled_date: 11.days.ago)
        create(:user_reading, user: inactive_user, reading: reading, completed_on: 11.days.ago)

        expect {
          described_class.perform_now
        }.to change { UserGroupEnrollment.where(user: inactive_user).count }.by(-1)
      end

      it "only considers readings from the same challenge" do
        other_challenge = create(:challenge, creator: owner)
        other_reading = create(:reading, challenge: other_challenge, scheduled_date: 2.days.ago)
        create(:user_challenge_enrollment, user: inactive_user, challenge: other_challenge)
        create(:user_reading, user: inactive_user, reading: other_reading, completed_on: 2.days.ago)

        # inactive_user has activity in other_challenge but not in this challenge
        expect {
          described_class.perform_now
        }.to change { UserGroupEnrollment.where(user: inactive_user, group: group).count }.by(-1)
      end
    end

    context "when challenge has auto_remove_inactive_from_groups disabled" do
      let(:challenge) { create(:challenge, creator: owner, auto_remove_inactive_from_groups: false) }
      let(:group) { create(:group, challenge: challenge, creator: owner) }
      let(:inactive_user) { create(:user) }

      before do
        create(:user_challenge_enrollment, user: inactive_user, challenge: challenge)
        create(:user_group_enrollment, user: inactive_user, group: group)
      end

      it "does not remove any users from groups" do
        expect {
          described_class.perform_now
        }.not_to change(UserGroupEnrollment, :count)
      end
    end

    context "with multiple challenges" do
      it "only processes challenges with the feature enabled" do
        enabled_challenge = create(:challenge, creator: owner, auto_remove_inactive_from_groups: true)
        disabled_challenge = create(:challenge, creator: owner, auto_remove_inactive_from_groups: false)

        enabled_group = create(:group, challenge: enabled_challenge, creator: owner)
        disabled_group = create(:group, challenge: disabled_challenge, creator: owner)

        user = create(:user)
        create(:user_challenge_enrollment, user: user, challenge: enabled_challenge)
        create(:user_challenge_enrollment, user: user, challenge: disabled_challenge)
        create(:user_group_enrollment, user: user, group: enabled_group)
        create(:user_group_enrollment, user: user, group: disabled_group)

        described_class.perform_now

        expect(UserGroupEnrollment.where(user: user, group: enabled_group).exists?).to be false
        expect(UserGroupEnrollment.where(user: user, group: disabled_group).exists?).to be true
      end
    end
  end
end
