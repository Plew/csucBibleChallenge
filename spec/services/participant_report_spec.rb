require "rails_helper"

RSpec.describe ParticipantReport do
  let(:challenge) { create(:challenge, name: "NT Challenge") }
  let(:user) { create(:user, username: "alice") }
  let(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge, role: "organizer") }
  let(:report) { described_class.new(challenge, enrollment).as_json }

  let!(:romans8)  { create(:reading, challenge: challenge, book_number: 45, chapter_number: 8) }
  let!(:romans12) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 12) }
  let(:group) { create(:group, challenge: challenge, name: "Munich") }

  before do
    enrollment
    create(:user_reading, user: user, reading: romans8,  completed_on: Date.new(2026, 1, 1))
    create(:user_reading, user: user, reading: romans12, completed_on: Date.new(2026, 1, 2))
    create(:verse_like, reading: romans8, user: user, verse_number: 1)
    create(:verse_message, reading: romans8, user: user, verse_number: 28, content: "love this verse")
    create(:user_group_enrollment, user: user, group: group)
  end

  it "describes the participant profile" do
    expect(report[:participant]).to include(user_id: user.id, username: "alice", role: "organizer")
  end

  it "summarizes the participant's stats" do
    expect(report[:stats]).to include(
      readings_completed: 2, readings_total: 2, completion_rate: 1.0,
      likes: 1, comments: 1, groups: 1
    )
  end

  it "lists the full reading history with references" do
    expect(report[:reading_history].size).to eq(2)
    expect(report[:reading_history].map { |r| r[:reference] }).to contain_exactly("Romans 8", "Romans 12")
    expect(report[:reading_history].first).to include(:completed_on, :scheduled_date)
  end

  it "lists group memberships" do
    expect(report[:groups]).to contain_exactly(include(id: group.id, name: "Munich"))
  end

  it "lists every like with a verse reference" do
    expect(report[:likes]).to contain_exactly(include(reference: "Romans 8:1", verse_number: 1))
  end

  it "lists every comment with content and reference" do
    expect(report[:comments]).to contain_exactly(
      include(reference: "Romans 8:28", verse_number: 28, content: "love this verse")
    )
  end

  it "excludes data tied to other challenges" do
    other = create(:challenge)
    other_reading = create(:reading, challenge: other, book_number: 1, chapter_number: 1)
    create(:user_reading, user: user, reading: other_reading, completed_on: Date.new(2026, 1, 3))
    create(:verse_like, reading: other_reading, user: user, verse_number: 1)

    expect(report[:reading_history].map { |r| r[:reading_id] }).not_to include(other_reading.id)
    expect(report[:likes].size).to eq(1)
  end
end
