require 'rails_helper'

RSpec.describe PerfectRecordStatistics do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner, timezone: "UTC", start_date: 10.days.ago.to_date) }

  describe ".call" do
    context "with no scheduled readings before today" do
      it "returns empty users and 0 days" do
        result = described_class.call(challenge: challenge)
        expect(result[:users]).to be_empty
        expect(result[:days_count]).to eq(0)
      end
    end

    context "with readings before today" do
      let(:user_perfect) { create(:user, username: "perfect_user") }
      let(:user_missed) { create(:user, username: "missed_user") }
      let(:user_late) { create(:user, username: "late_user") }

      before do
        create(:user_challenge_enrollment, user: user_perfect, challenge: challenge)
        create(:user_challenge_enrollment, user: user_missed, challenge: challenge)
        create(:user_challenge_enrollment, user: user_late, challenge: challenge)

        # Create 5 readings scheduled before today
        5.times do |i|
          reading = create(:reading,
            challenge: challenge,
            scheduled_date: (i + 1).days.ago.to_date,
            book_number: 1,
            chapter_number: i + 1
          )

          # perfect_user completes all on time
          create(:user_reading, user: user_perfect, reading: reading, completed_on: reading.scheduled_date)

          # missed_user completes only 4 of 5
          if i < 4
            create(:user_reading, user: user_missed, reading: reading, completed_on: reading.scheduled_date)
          end

          # late_user completes all but one is late
          if i == 0
            create(:user_reading, user: user_late, reading: reading, completed_on: reading.scheduled_date + 1.day)
          else
            create(:user_reading, user: user_late, reading: reading, completed_on: reading.scheduled_date)
          end
        end
      end

      it "includes users with 100% completion and 100% on-time" do
        result = described_class.call(challenge: challenge)
        usernames = result[:users].map(&:username)
        expect(usernames).to include("perfect_user")
      end

      it "excludes users who missed a reading" do
        result = described_class.call(challenge: challenge)
        usernames = result[:users].map(&:username)
        expect(usernames).not_to include("missed_user")
      end

      it "excludes users who completed a reading late" do
        result = described_class.call(challenge: challenge)
        usernames = result[:users].map(&:username)
        expect(usernames).not_to include("late_user")
      end

      it "returns the correct days count" do
        result = described_class.call(challenge: challenge)
        expect(result[:days_count]).to eq((Date.current - challenge.start_date).to_i)
      end
    end

    context "excluding today's readings" do
      let(:user) { create(:user) }

      before do
        create(:user_challenge_enrollment, user: user, challenge: challenge)

        # Reading from yesterday - completed on time
        yesterday_reading = create(:reading,
          challenge: challenge,
          scheduled_date: 1.day.ago.to_date,
          book_number: 1,
          chapter_number: 1
        )
        create(:user_reading, user: user, reading: yesterday_reading, completed_on: 1.day.ago.to_date)

        # Today's reading - NOT completed yet
        create(:reading,
          challenge: challenge,
          scheduled_date: Date.current,
          book_number: 1,
          chapter_number: 2
        )
      end

      it "does not penalize for unread today's reading" do
        result = described_class.call(challenge: challenge)
        usernames = result[:users].map(&:username)
        expect(usernames).to include(user.username)
      end
    end

    context "with users not enrolled in the challenge" do
      let(:user) { create(:user) }

      before do
        # User has readings but is NOT enrolled
        reading = create(:reading, challenge: challenge, scheduled_date: 1.day.ago.to_date)
        create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
      end

      it "excludes users not enrolled in the challenge" do
        result = described_class.call(challenge: challenge)
        expect(result[:users]).to be_empty
      end
    end

    context "efficiency" do
      it "uses a bounded number of queries regardless of user count" do
        users = create_list(:user, 10)
        reading = create(:reading, challenge: challenge, scheduled_date: 1.day.ago.to_date)

        users.each do |user|
          create(:user_challenge_enrollment, user: user, challenge: challenge)
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end

        query_count = 0
        counter = ->(_name, _started, _finished, _unique_id, payload) {
          query_count += 1 unless payload[:name] == "SCHEMA" || payload[:name] == "CACHE"
        }

        ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
          described_class.call(challenge: challenge)
        end

        # Should use a fixed number of queries, not N+1
        expect(query_count).to be <= 6
      end
    end
  end
end
