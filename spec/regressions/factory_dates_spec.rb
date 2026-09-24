require 'rails_helper'

RSpec.describe 'Factory dates at timezone boundaries' do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    Time.use_zone('Eastern Time (US & Canada)') { example.run }
  end

  [ Time.utc(2026, 9, 24, 1), Time.utc(2026, 1, 24, 2), Time.utc(2026, 9, 24, 17) ].each do |instant|
    it "keeps default dates aligned with the application at #{instant.iso8601}" do
      travel_to(instant) do
        challenge = create(:challenge)
        reading = create(:reading, challenge: challenge)
        completion = create(:user_reading, reading: reading)

        expect(challenge.start_date).to eq(Date.current)
        expect(challenge.end_date).to eq(Date.current + 1.month)
        expect(challenge).to be_in_progress
        expect(reading.scheduled_date).to eq(Date.current)
        expect(completion.completed_on).to eq(Date.current)
        expect { challenge.update!(end_date: Date.current) }.not_to raise_error
      end
    end
  end
end
