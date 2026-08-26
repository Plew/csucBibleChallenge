require 'rails_helper'

RSpec.describe "Home Page Reading Statuses", type: :request do
  def log_in_as(user)
    post user_session_path, params: { session: { email: user.email, password: "password123" } }
  end

  let(:user) { create(:user) }
  let(:today) { Date.current }

  let!(:challenge1) do
    create(:challenge,
      name: "Challenge Alpha",
      start_date: 1.week.ago,
      end_date: 1.week.from_now,
      timezone: "UTC"
    )
  end

  let!(:challenge2) do
    create(:challenge,
      name: "Challenge Beta",
      start_date: 1.week.ago,
      end_date: 1.week.from_now,
      timezone: "UTC"
    )
  end

  let!(:reading1) { create(:reading, challenge: challenge1, book_number: 40, chapter_number: 1, scheduled_date: today) }
  let!(:reading2) { create(:reading, challenge: challenge2, book_number: 43, chapter_number: 1, scheduled_date: today) }

  before do
    create(:user_challenge_enrollment, user: user, challenge: challenge1)
    create(:user_challenge_enrollment, user: user, challenge: challenge2)
    log_in_as(user)
  end

  it "shows unread status for both challenges when nothing is read" do
    get root_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Challenge Alpha")
    expect(response.body).to include("Challenge Beta")
    expect(response.body).to include("Unread today")
  end

  it "shows 'Read today' when user completes today's reading for a challenge" do
    create(:user_reading, user: user, reading: reading1)

    get root_path

    expect(response.body).to include("Read today (Matthew 1)")
  end

  it "shows partial completion when a multi-chapter challenge is partially read" do
    reading1_b = create(:reading, challenge: challenge1, book_number: 40, chapter_number: 2, scheduled_date: today)
    create(:user_reading, user: user, reading: reading1)

    get root_path

    expect(response.body).to include("1/2 Read Today")
  end

  it "shows rest day when no readings are scheduled for today" do
    reading2.destroy!

    get root_path

    expect(response.body).to include("Rest / Catch-up day")
  end

  it "renders the theme-aware ambient background elements" do
    get root_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("ambient-light")
    expect(response.body).to include("ambient-dark")
  end
end
