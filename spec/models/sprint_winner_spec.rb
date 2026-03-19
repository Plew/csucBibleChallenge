require 'rails_helper'

RSpec.describe SprintWinner, type: :model do
  describe "associations" do
    it { should belong_to(:sprint) }
    it { should belong_to(:group).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:completion_percentage) }
    it { should validate_presence_of(:on_schedule_percentage) }

    it "validates uniqueness of sprint_id scoped to group_id" do
      challenge = create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31))
      sprint = create(:sprint, challenge: challenge)
      group = create(:group, challenge: challenge)
      create(:sprint_winner, sprint: sprint, group: group, completion_percentage: 80, on_schedule_percentage: 70)

      duplicate = build(:sprint_winner, sprint: sprint, group: group, completion_percentage: 90, on_schedule_percentage: 85)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:sprint_id]).to be_present
    end
  end
end
