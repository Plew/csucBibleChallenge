require "rails_helper"

RSpec.describe GroupReport do
  let(:challenge) do
    create(:challenge, name: "NT Challenge",
                       start_date: Date.current - 10, end_date: Date.current + 10)
  end
  let(:group) { create(:group, challenge: challenge, name: "Munich", country_code: "DE", motto: "Read on") }
  let(:report) { described_class.new(challenge, group).as_json }

  let(:alice) { create(:user, username: "alice") }
  let(:bob)   { create(:user, username: "bob") }

  let!(:reading1) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 8, scheduled_date: Date.current - 5) }
  let!(:reading2) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 12, scheduled_date: Date.current - 3) }

  before do
    create(:user_challenge_enrollment, user: alice, challenge: challenge, role: "organizer")
    create(:user_challenge_enrollment, user: bob, challenge: challenge, role: "member")
    create(:user_group_enrollment, user: alice, group: group)
    create(:user_group_enrollment, user: bob, group: group)

    create(:user_reading, user: alice, reading: reading1, completed_on: reading1.scheduled_date)
    create(:user_reading, user: alice, reading: reading2, completed_on: reading2.scheduled_date)
    create(:user_reading, user: bob, reading: reading1, completed_on: reading1.scheduled_date)
  end

  it "describes the group profile" do
    expect(report[:group]).to include(
      id: group.id, name: "Munich", motto: "Read on", country_code: "DE",
      creator: { id: group.creator_id, username: group.creator.username }
    )
    expect(report[:group][:country]).to be_present
  end

  it "summarizes aggregate group stats" do
    expect(report[:stats]).to include(:completion_percentage, :on_schedule_percentage,
                                      :longest_group_streak, :total_chapters_read)
    expect(report[:stats][:members]).to eq(2)
    expect(report[:stats][:total_chapters_read]).to eq(3)
  end

  it "lists members with their challenge role and progress" do
    expect(report[:members].size).to eq(2)
    alice_row = report[:members].find { |m| m[:user_id] == alice.id }
    expect(alice_row).to include(username: "alice", role: "organizer", readings_completed: 2)
    expect(alice_row).to include(:joined_group_at, :last_completed_on)
  end

  context "with a sprint" do
    let!(:sprint) do
      create(:sprint, challenge: challenge, title: "Week 1",
                      begin_date: Date.current - 7, end_date: Date.current - 1)
    end

    before { create(:sprint_winner, sprint: sprint, group: group) }

    it "reports the group's per-sprint performance and win flag" do
      row = report[:sprints].find { |s| s[:sprint_id] == sprint.id }
      expect(row).to include(title: "Week 1", begin_date: sprint.begin_date, end_date: sprint.end_date, won: true)
      expect(row).to include(:completion_percentage, :on_schedule_percentage, :status)
    end
  end
end
