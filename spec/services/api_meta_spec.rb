require "rails_helper"

RSpec.describe ApiMeta do
  let(:challenge) { create(:challenge, name: "NT Challenge") }
  let(:meta) { described_class.new(challenge, base_url: "https://example.test").as_json }

  before do
    reading = create(:reading, challenge: challenge, book_number: 45, chapter_number: 8)
    create(:reading, challenge: challenge, book_number: 45, chapter_number: 12)
    user = create(:user)
    create(:user_challenge_enrollment, user: user, challenge: challenge)
    create(:verse_like, reading: reading, user: user, verse_number: 1)
  end

  it "describes auth and the challenge" do
    expect(meta[:auth][:scheme]).to eq("Bearer")
    expect(meta[:challenge][:id]).to eq(challenge.id)
  end

  it "lists the meta and report endpoints with absolute URLs" do
    paths = meta[:endpoints].map { |e| e[:path] }
    expect(paths).to include("/api/v1/meta", "/api/v1/challenges/#{challenge.id}/report")
    expect(meta[:endpoints]).to all(include(url: a_string_starting_with("https://example.test")))
  end

  it "includes a field glossary" do
    expect(meta[:field_glossary]).to include("stats.completion_rate", "top_liked_verses")
  end

  it "includes a live report shape with arrays truncated to one sample row" do
    shape = meta[:example_report_shape]
    expect(shape).to include(:challenge, :stats, :readings, :participants, :top_liked_verses)
    expect(shape[:readings].size).to be <= 1
    expect(shape[:participants].size).to be <= 1
    expect(shape[:top_liked_verses].size).to be <= 1
    # Hash sections are preserved in full
    expect(shape[:stats][:participants]).to eq(1)
  end
end
