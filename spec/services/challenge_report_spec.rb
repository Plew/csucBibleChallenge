require "rails_helper"

RSpec.describe ChallengeReport do
  let(:challenge) { create(:challenge, name: "NT Challenge") }
  let(:report) { described_class.new(challenge).as_json }

  describe "#as_json" do
    let(:alice) { create(:user, username: "alice") }
    let(:bob)   { create(:user, username: "bob") }
    let!(:romans8)  { create(:reading, challenge: challenge, book_number: 45, chapter_number: 8, scheduled_date: Date.new(2026, 1, 1)) }
    let!(:romans12) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 12, scheduled_date: Date.new(2026, 1, 2)) }

    before do
      create(:user_challenge_enrollment, user: alice, challenge: challenge, role: "organizer")
      create(:user_challenge_enrollment, user: bob, challenge: challenge)

      create(:user_reading, user: alice, reading: romans8,  completed_on: Date.new(2026, 1, 1))
      create(:user_reading, user: alice, reading: romans12, completed_on: Date.new(2026, 1, 2))
      create(:user_reading, user: bob,   reading: romans8,  completed_on: Date.new(2026, 1, 1))

      # Romans 8:1 liked twice, Romans 12:5 liked once
      create(:verse_like, reading: romans8,  user: alice, verse_number: 1)
      create(:verse_like, reading: romans8,  user: bob,   verse_number: 1)
      create(:verse_like, reading: romans12, user: alice, verse_number: 5)
    end

    it "includes challenge metadata and creator" do
      expect(report[:challenge][:name]).to eq("NT Challenge")
      expect(report[:challenge][:status]).to be_present
      expect(report[:challenge][:creator][:username]).to eq(challenge.creator.username)
    end

    it "summarizes stats" do
      expect(report[:stats][:participants]).to eq(2)
      expect(report[:stats][:readings]).to eq(2)
      expect(report[:stats][:total_completions]).to eq(3)
      expect(report[:stats][:total_verse_likes]).to eq(3)
      expect(report[:stats][:completion_rate]).to eq((3.0 / 4).round(4))
    end

    it "lists readings with completion counts and a reference" do
      row = report[:readings].find { |r| r[:id] == romans8.id }
      expect(row[:completions]).to eq(2)
      expect(row[:reference]).to eq("Romans 8")
    end

    it "lists participants with role and progress" do
      alice_row = report[:participants].find { |p| p[:username] == "alice" }
      expect(alice_row[:role]).to eq("organizer")
      expect(alice_row[:readings_completed]).to eq(2)
      expect(alice_row[:last_completed_on]).to eq(Date.new(2026, 1, 2))
    end

    it "does not expose participant emails" do
      expect(report[:participants]).to all(satisfy { |p| !p.key?(:email) })
    end

    it "ranks the most-liked verses" do
      top = report[:top_liked_verses].first
      expect(top[:reference]).to eq("Romans 8:1")
      expect(top[:likes]).to eq(2)
    end
  end
end
