require "rails_helper"

RSpec.describe SprintStandings do
  let(:challenge) do
    create(:challenge, start_date: Date.current - 10, end_date: Date.current + 10)
  end
  let(:sprint) do
    create(:sprint, challenge: challenge, title: "Week 1",
                    begin_date: Date.current - 7, end_date: Date.current - 1)
  end
  let(:standings) { described_class.new(sprint).as_json[:standings] }

  let!(:reading1) { create(:reading, challenge: challenge, scheduled_date: Date.current - 5) }
  let!(:reading2) { create(:reading, challenge: challenge, scheduled_date: Date.current - 3) }

  # Lions and Tigers each have one member who completed both readings; Bears'
  # member completed only one. Ghosts has no members.
  let(:lions)  { create(:group, challenge: challenge, name: "Lions") }
  let(:tigers) { create(:group, challenge: challenge, name: "Tigers") }
  let(:bears)  { create(:group, challenge: challenge, name: "Bears") }
  let!(:ghosts) { create(:group, challenge: challenge, name: "Ghosts") }

  before do
    [ lions, tigers ].each do |group|
      member = create(:user)
      create(:user_group_enrollment, user: member, group: group)
      create(:user_reading, user: member, reading: reading1, completed_on: reading1.scheduled_date)
      create(:user_reading, user: member, reading: reading2, completed_on: reading2.scheduled_date)
    end

    bear = create(:user)
    create(:user_group_enrollment, user: bear, group: bears)
    create(:user_reading, user: bear, reading: reading1, completed_on: reading1.scheduled_date)
  end

  it "ranks groups by completion then on-schedule percentage" do
    by_name = standings.index_by { |s| s[:group_name] }

    expect(by_name["Lions"][:completion_percentage]).to eq(100)
    expect(by_name["Bears"][:completion_percentage]).to eq(50)
    expect(by_name["Bears"][:rank]).to be > by_name["Lions"][:rank]
  end

  it "gives tied groups the same rank (competition ranking)" do
    ranks = standings.map { |s| s[:rank] }
    expect(ranks.sort).to eq([ 1, 1, 3 ])

    bears = standings.find { |s| s[:group_name] == "Bears" }
    expect(bears[:rank]).to eq(3)
  end

  it "excludes groups that have no members" do
    expect(standings.map { |s| s[:group_name] }).not_to include("Ghosts")
  end

  it "includes the sprint's start and end dates" do
    sprint_hash = described_class.new(sprint).as_json[:sprint]
    expect(sprint_hash).to include(begin_date: sprint.begin_date, end_date: sprint.end_date, status: "past")
  end
end
