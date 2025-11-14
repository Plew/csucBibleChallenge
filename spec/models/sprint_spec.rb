require 'rails_helper'

RSpec.describe Sprint, type: :model do
  describe "associations" do
    it { should belong_to(:challenge) }
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
end
