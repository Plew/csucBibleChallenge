require 'rails_helper'

RSpec.describe StatWindow, type: :model do
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
        stat_window = build(:stat_window, challenge: challenge, begin_date: Date.new(2025, 6, 1), end_date: Date.new(2025, 5, 1))
        expect(stat_window).not_to be_valid
        expect(stat_window.errors[:end_date]).to include("must be on or after the begin date")
      end

      it "allows end_date to equal begin_date" do
        stat_window = build(:stat_window, challenge: challenge, begin_date: Date.new(2025, 6, 1), end_date: Date.new(2025, 6, 1))
        expect(stat_window).to be_valid
      end

      it "validates begin_date is within challenge date range" do
        stat_window = build(:stat_window, challenge: challenge, begin_date: Date.new(2024, 12, 31), end_date: Date.new(2025, 6, 1))
        expect(stat_window).not_to be_valid
        expect(stat_window.errors[:begin_date]).to include("must be on or after the challenge start date (2025-01-01)")
      end

      it "validates end_date is within challenge date range" do
        stat_window = build(:stat_window, challenge: challenge, begin_date: Date.new(2025, 6, 1), end_date: Date.new(2026, 1, 1))
        expect(stat_window).not_to be_valid
        expect(stat_window.errors[:end_date]).to include("must be on or before the challenge end date (2025-12-31)")
      end

      it "is valid when dates are within challenge range" do
        stat_window = build(:stat_window, challenge: challenge, begin_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 6, 30))
        expect(stat_window).to be_valid
      end
    end
  end

  describe "scopes" do
    let(:challenge) { create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }
    let!(:window1) { create(:stat_window, challenge: challenge, begin_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 3, 31)) }
    let!(:window2) { create(:stat_window, challenge: challenge, begin_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 31)) }
    let!(:window3) { create(:stat_window, challenge: challenge, begin_date: Date.new(2025, 6, 1), end_date: Date.new(2025, 6, 30)) }

    describe ".for_challenge" do
      it "returns stat windows for a specific challenge" do
        other_challenge = create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31))
        other_window = create(:stat_window, challenge: other_challenge, begin_date: Date.new(2025, 2, 1), end_date: Date.new(2025, 2, 28))

        windows = StatWindow.for_challenge(challenge.id)
        expect(windows).to contain_exactly(window1, window2, window3)
        expect(windows).not_to include(other_window)
      end
    end

    describe ".ordered" do
      it "returns stat windows ordered by begin_date ascending" do
        windows = StatWindow.ordered
        expect(windows).to eq([ window2, window1, window3 ])
      end
    end
  end

  describe "#date_range" do
    it "returns a range from begin_date to end_date" do
      stat_window = build(:stat_window, begin_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 6, 30))
      expect(stat_window.date_range).to eq(Date.new(2025, 3, 1)..Date.new(2025, 6, 30))
    end
  end
end
