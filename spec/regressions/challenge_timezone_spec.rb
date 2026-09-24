require 'rails_helper'

RSpec.describe 'Challenge dates across timezones', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    Time.use_zone('Eastern Time (US & Canada)') do
      travel_to(Time.utc(2026, 9, 24, 1)) { example.run }
    end
  end

  it 'uses the UTC challenge date for catch-up and perfect records even on the previous Eastern date' do
    expect(Date.current).to eq(Date.new(2026, 9, 23))
    challenge = create(:challenge, timezone: 'UTC', start_date: Date.new(2026, 9, 20))
    user = create(:user)
    create(:user_challenge_enrollment, user: user, challenge: challenge)
    yesterday = create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 23))
    create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 24))
    login_via_session(user)

    get challenge_catch_up_path(challenge)
    expect(response.body).to include(I18n.t('catch_up.heading', count: 1))

    create(:user_reading, user: user, reading: yesterday, completed_on: yesterday.scheduled_date)
    get challenge_catch_up_path(challenge)
    expect(response.body).to include(CGI.escapeHTML(I18n.t('catch_up.all_caught_up')))

    result = PerfectRecordStatistics.call(challenge: challenge)
    expect(result[:users].map(&:id)).to include(user.id)
    expect(result[:days_count]).to eq(4)
  end
end
