require 'rails_helper'

RSpec.describe CalculateSprintWinnersJob, type: :job do
  describe "#perform" do
    let(:challenge) { create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2027, 12, 31), timezone: "Berlin") }

    it "calculates winners for sprints that ended yesterday in challenge timezone" do
      tz = ActiveSupport::TimeZone["Berlin"]
      yesterday = tz.now.to_date - 1.day

      sprint = create(:sprint, challenge: challenge, begin_date: yesterday - 30.days, end_date: yesterday)
      group = create(:group, challenge: challenge)
      create(:user_group_enrollment, group: group)

      allow_any_instance_of(GroupStatistics).to receive(:completion_percentage).and_return(85)
      allow_any_instance_of(GroupStatistics).to receive(:on_schedule_percentage).and_return(75)

      described_class.perform_now

      expect(sprint.sprint_winners.count).to eq(1)
    end

    it "skips sprints that already have winners" do
      tz = ActiveSupport::TimeZone["Berlin"]
      yesterday = tz.now.to_date - 1.day

      sprint = create(:sprint, challenge: challenge, begin_date: yesterday - 30.days, end_date: yesterday)
      group = create(:group, challenge: challenge)
      create(:user_group_enrollment, group: group)
      create(:sprint_winner, sprint: sprint, group: group)

      expect { described_class.perform_now }.not_to change { SprintWinner.count }
    end

    it "does not process sprints that did not end yesterday" do
      tz = ActiveSupport::TimeZone["Berlin"]
      today = tz.now.to_date

      sprint = create(:sprint, challenge: challenge, begin_date: today - 30.days, end_date: today)
      group = create(:group, challenge: challenge)
      create(:user_group_enrollment, group: group)

      described_class.perform_now

      expect(sprint.sprint_winners.count).to eq(0)
    end
  end
end
