require 'rails_helper'

RSpec.describe Sprint, type: :model do
  describe "associations" do
    it { should belong_to(:challenge) }
    it { should have_many(:sprint_winners).dependent(:destroy) }
    it { should have_many(:winner_groups).through(:sprint_winners) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:begin_date) }
    it { should validate_presence_of(:end_date) }

    context "date validations" do
      let(:challenge) { create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }

      it "validates end_date is after begin_date" do
        sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 6, 1), end_date: Date.new(2025, 5, 1))
        expect(sprint).not_to be_valid
        expect(sprint.errors[:end_date]).to include("must be on or after the begin date")
      end

      it "allows end_date to equal begin_date" do
        sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 6, 1), end_date: Date.new(2025, 6, 1))
        expect(sprint).to be_valid
      end

      it "validates begin_date is within challenge date range" do
        sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2024, 12, 31), end_date: Date.new(2025, 6, 1))
        expect(sprint).not_to be_valid
        expect(sprint.errors[:begin_date]).to include("must be on or after the challenge start date (2025-01-01)")
      end

      it "validates end_date is within challenge date range" do
        sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 6, 1), end_date: Date.new(2026, 1, 1))
        expect(sprint).not_to be_valid
        expect(sprint.errors[:end_date]).to include("must be on or before the challenge end date (2025-12-31)")
      end

      it "is valid when dates are within challenge range" do
        sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 6, 30))
        expect(sprint).to be_valid
      end
    end

    context "overlapping date validations" do
      let(:challenge) { create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }
      let!(:existing_sprint) { create(:sprint, challenge: challenge, begin_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 3, 31)) }

      it "prevents creating a sprint that completely overlaps an existing sprint" do
        overlapping_sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 3, 10), end_date: Date.new(2025, 3, 20))
        expect(overlapping_sprint).not_to be_valid
        expect(overlapping_sprint.errors[:base]).to include("Sprint dates overlap with existing sprint in this challenge")
      end

      it "prevents creating a sprint that starts before and ends during an existing sprint" do
        overlapping_sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 2, 15), end_date: Date.new(2025, 3, 15))
        expect(overlapping_sprint).not_to be_valid
        expect(overlapping_sprint.errors[:base]).to include("Sprint dates overlap with existing sprint in this challenge")
      end

      it "prevents creating a sprint that starts during and ends after an existing sprint" do
        overlapping_sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 3, 15), end_date: Date.new(2025, 4, 15))
        expect(overlapping_sprint).not_to be_valid
        expect(overlapping_sprint.errors[:base]).to include("Sprint dates overlap with existing sprint in this challenge")
      end

      it "prevents creating a sprint that completely contains an existing sprint" do
        overlapping_sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 2, 1), end_date: Date.new(2025, 4, 30))
        expect(overlapping_sprint).not_to be_valid
        expect(overlapping_sprint.errors[:base]).to include("Sprint dates overlap with existing sprint in this challenge")
      end

      it "prevents creating a sprint that touches the end date of an existing sprint" do
        touching_sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 3, 31), end_date: Date.new(2025, 4, 30))
        expect(touching_sprint).not_to be_valid
        expect(touching_sprint.errors[:base]).to include("Sprint dates overlap with existing sprint in this challenge")
      end

      it "prevents creating a sprint that touches the start date of an existing sprint" do
        touching_sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 2, 1), end_date: Date.new(2025, 3, 1))
        expect(touching_sprint).not_to be_valid
        expect(touching_sprint.errors[:base]).to include("Sprint dates overlap with existing sprint in this challenge")
      end

      it "allows creating a sprint with gaps between existing sprints" do
        non_overlapping_sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 5, 1), end_date: Date.new(2025, 5, 31))
        expect(non_overlapping_sprint).to be_valid
      end

      it "allows creating a sprint before an existing sprint with a gap" do
        non_overlapping_sprint = build(:sprint, challenge: challenge, begin_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 2, 28))
        expect(non_overlapping_sprint).to be_valid
      end

      it "allows updating an existing sprint without overlap errors" do
        existing_sprint.title = "Updated Sprint Title"
        expect(existing_sprint).to be_valid
      end

      it "allows updating an existing sprint's dates within its own range" do
        existing_sprint.begin_date = Date.new(2025, 3, 2)
        existing_sprint.end_date = Date.new(2025, 3, 30)
        expect(existing_sprint).to be_valid
      end

      it "allows creating a sprint in a different challenge with same dates" do
        other_challenge = create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31))
        same_dates_sprint = build(:sprint, challenge: other_challenge, begin_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 3, 31))
        expect(same_dates_sprint).to be_valid
      end
    end
  end

  describe "scopes" do
    let(:challenge) { create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }
    let!(:sprint1) { create(:sprint, challenge: challenge, begin_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 3, 31)) }
    let!(:sprint2) { create(:sprint, challenge: challenge, begin_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 31)) }
    let!(:sprint3) { create(:sprint, challenge: challenge, begin_date: Date.new(2025, 6, 1), end_date: Date.new(2025, 6, 30)) }

    describe ".for_challenge" do
      it "returns sprints for a specific challenge" do
        other_challenge = create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31))
        other_sprint = create(:sprint, challenge: other_challenge, begin_date: Date.new(2025, 2, 1), end_date: Date.new(2025, 2, 28))

        sprints = Sprint.for_challenge(challenge.id)
        expect(sprints).to contain_exactly(sprint1, sprint2, sprint3)
        expect(sprints).not_to include(other_sprint)
      end
    end

    describe ".ordered" do
      it "returns sprints ordered by begin_date ascending" do
        sprints = Sprint.ordered
        expect(sprints).to eq([ sprint2, sprint1, sprint3 ])
      end
    end
  end

  describe "#date_range" do
    it "returns a range from begin_date to end_date" do
      sprint = build(:sprint, begin_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 6, 30))
      expect(sprint.date_range).to eq(Date.new(2025, 3, 1)..Date.new(2025, 6, 30))
    end
  end

  describe "#winners_calculated?" do
    let(:challenge) { create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }
    let(:sprint) { create(:sprint, challenge: challenge) }

    it "returns false when no sprint_winners exist" do
      expect(sprint.winners_calculated?).to be false
    end

    it "returns true when sprint_winners exist" do
      group = create(:group, challenge: challenge)
      create(:sprint_winner, sprint: sprint, group: group)
      expect(sprint.winners_calculated?).to be true
    end
  end

  describe "#calculate_winners!" do
    let(:challenge) { create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }
    let(:sprint) { create(:sprint, challenge: challenge, begin_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 31)) }

    it "does nothing when no groups with members exist" do
      create(:group, challenge: challenge) # group without members
      sprint.calculate_winners!
      expect(sprint.sprint_winners).to be_empty
    end

    it "creates a single winner when one group leads" do
      group1 = create(:group, challenge: challenge)
      group2 = create(:group, challenge: challenge)
      create(:user_group_enrollment, group: group1)
      create(:user_group_enrollment, group: group2)

      stats1 = instance_double(GroupStatistics, completion_percentage: 80, on_schedule_percentage: 70)
      stats2 = instance_double(GroupStatistics, completion_percentage: 60, on_schedule_percentage: 50)
      allow(GroupStatistics).to receive(:new).with(group1, anything).and_return(stats1)
      allow(GroupStatistics).to receive(:new).with(group2, anything).and_return(stats2)

      sprint.calculate_winners!

      expect(sprint.sprint_winners.count).to eq(1)
      winner = sprint.sprint_winners.first
      expect(winner.group).to eq(group1)
      expect(winner.completion_percentage).to eq(80)
      expect(winner.on_schedule_percentage).to eq(70)
    end

    it "creates multiple winners when groups are tied on both metrics" do
      group1 = create(:group, challenge: challenge)
      group2 = create(:group, challenge: challenge)
      create(:user_group_enrollment, group: group1)
      create(:user_group_enrollment, group: group2)

      stats = instance_double(GroupStatistics, completion_percentage: 80, on_schedule_percentage: 70)
      allow(GroupStatistics).to receive(:new).and_return(stats)

      sprint.calculate_winners!

      expect(sprint.sprint_winners.count).to eq(2)
      expect(sprint.winner_groups).to contain_exactly(group1, group2)
    end

    it "uses on_schedule_percentage as tiebreaker when completion is tied" do
      group1 = create(:group, challenge: challenge)
      group2 = create(:group, challenge: challenge)
      create(:user_group_enrollment, group: group1)
      create(:user_group_enrollment, group: group2)

      stats1 = instance_double(GroupStatistics, completion_percentage: 80, on_schedule_percentage: 90)
      stats2 = instance_double(GroupStatistics, completion_percentage: 80, on_schedule_percentage: 70)
      allow(GroupStatistics).to receive(:new).with(group1, anything).and_return(stats1)
      allow(GroupStatistics).to receive(:new).with(group2, anything).and_return(stats2)

      sprint.calculate_winners!

      expect(sprint.sprint_winners.count).to eq(1)
      expect(sprint.winner_groups.first).to eq(group1)
    end

    it "is idempotent — does not recalculate if winners already exist" do
      group = create(:group, challenge: challenge)
      create(:user_group_enrollment, group: group)
      create(:sprint_winner, sprint: sprint, group: group)

      expect { sprint.calculate_winners! }.not_to change { sprint.sprint_winners.count }
    end
  end
end
