# frozen_string_literal: true

require "rails_helper"

RSpec.describe BadgeAwarder do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, start_date: 60.days.ago.to_date, end_date: 60.days.from_now.to_date) }

  before do
    create(:user_challenge_enrollment, user: user, challenge: challenge)
  end

  describe "#call" do
    it "returns empty array when no badges earned" do
      awarder = BadgeAwarder.new(user, challenge)
      expect(awarder.call).to eq([])
    end

    it "is idempotent — does not re-award existing badges" do
      50.times do |i|
        reading = create(:reading, challenge: challenge, scheduled_date: (50 - i).days.ago.to_date, book_number: 1, chapter_number: i + 1)
        create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
      end

      BadgeAwarder.new(user, challenge).call
      result = BadgeAwarder.new(user, challenge).call
      expect(result).to eq([])
      expect(user.user_badges.where(challenge: challenge, badge_key: "chapters_50").count).to eq(1)
    end

    context "chapter badges" do
      it "awards chapters_50 when 50 chapters completed" do
        50.times do |i|
          reading = create(:reading, challenge: challenge, scheduled_date: (50 - i).days.ago.to_date, book_number: 1, chapter_number: i + 1)
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("chapters_50")
      end
    end

    context "streak badges" do
      it "awards streak_7 for 7 consecutive days" do
        7.times do |i|
          date = (7 - i).days.ago.to_date
          reading = create(:reading, challenge: challenge, scheduled_date: date, book_number: 1, chapter_number: i + 1)
          create(:user_reading, user: user, reading: reading, completed_on: date)
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("streak_7")
      end
    end

    context "perfect record badges" do
      it "awards perfect_week for any 7 consecutive perfect days" do
        7.times do |i|
          date = challenge.start_date + 10.days + i.days
          reading = create(:reading, challenge: challenge, scheduled_date: date, book_number: 1, chapter_number: i + 1)
          create(:user_reading, user: user, reading: reading, completed_on: date)
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("perfect_week")
      end
    end

    context "social badges" do
      it "awards verse_lover when user likes 20 verses" do
        20.times do |i|
          reading = create(:reading, challenge: challenge, scheduled_date: Date.current - i.days, book_number: 1, chapter_number: i + 1)
          create(:verse_like, user: user, reading: reading, verse_number: 1)
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("verse_lover")
      end

      it "does not award verse_lover with fewer than 20 likes" do
        19.times do |i|
          reading = create(:reading, challenge: challenge, scheduled_date: Date.current - i.days, book_number: 1, chapter_number: i + 1)
          create(:verse_like, user: user, reading: reading, verse_number: 1)
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).not_to include("verse_lover")
      end
    end

    context "fun badges" do
      it "awards crack_of_dawn for 10 readings logged between 5am and 6am" do
        tz = ActiveSupport::TimeZone[challenge.timezone]
        10.times do |i|
          date = (5 - i).days.ago.to_date
          reading = create(:reading, challenge: challenge, scheduled_date: date, book_number: 1, chapter_number: i + 1)
          early_time = tz.local(date.year, date.month, date.day, 5, 15)
          ur = create(:user_reading, user: user, reading: reading, completed_on: date)
          ur.update_column(:created_at, early_time)
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("crack_of_dawn")
      end

      it "awards go_to_bed for 10 readings logged between 11:30pm and midnight" do
        tz = ActiveSupport::TimeZone[challenge.timezone]
        10.times do |i|
          date = (10 - i).days.ago.to_date
          reading = create(:reading, challenge: challenge, scheduled_date: date, book_number: 1, chapter_number: i + 1)
          late_time = tz.local(date.year, date.month, date.day, 23, 45)
          ur = create(:user_reading, user: user, reading: reading, completed_on: date)
          ur.update_column(:created_at, late_time)
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("go_to_bed")
      end

      it "awards just_barely for a reading logged at 11:59pm" do
        tz = ActiveSupport::TimeZone[challenge.timezone]
        date = 1.day.ago.to_date
        reading = create(:reading, challenge: challenge, scheduled_date: date, book_number: 1, chapter_number: 1)
        last_minute_time = tz.local(date.year, date.month, date.day, 23, 59, 30)
        ur = create(:user_reading, user: user, reading: reading, completed_on: date)
        ur.update_column(:created_at, last_minute_time)

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("just_barely")
      end

      it "awards slightly_sus for 10+ readings in a single day" do
        date = 1.day.ago.to_date
        10.times do |i|
          reading = create(:reading, challenge: challenge, scheduled_date: date - i.days, book_number: 1, chapter_number: i + 1)
          ur = create(:user_reading, user: user, reading: reading, completed_on: date - i.days)
          # Set all created_at to same date
          ur.update_column(:created_at, Time.zone.local(date.year, date.month, date.day, 10, i))
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("slightly_sus")
      end

      it "awards i_have_returned for a gap of more than 10 days" do
        # First reading
        date1 = 25.days.ago.to_date
        r1 = create(:reading, challenge: challenge, scheduled_date: date1, book_number: 1, chapter_number: 1)
        ur1 = create(:user_reading, user: user, reading: r1, completed_on: date1)
        ur1.update_column(:created_at, Time.zone.local(date1.year, date1.month, date1.day, 10, 0))

        # Second reading 14 days later (gap > 10)
        date2 = 11.days.ago.to_date
        r2 = create(:reading, challenge: challenge, scheduled_date: date2, book_number: 1, chapter_number: 2)
        ur2 = create(:user_reading, user: user, reading: r2, completed_on: date2)
        ur2.update_column(:created_at, Time.zone.local(date2.year, date2.month, date2.day, 10, 0))

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("i_have_returned")
      end

      it "awards lone_wolf for 15 consecutive perfect days without a group" do
        15.times do |i|
          date = challenge.start_date + 5.days + i.days
          reading = create(:reading, challenge: challenge, scheduled_date: date, book_number: 1, chapter_number: i + 1)
          create(:user_reading, user: user, reading: reading, completed_on: date)
        end

        result = BadgeAwarder.new(user, challenge).call
        expect(result).to include("lone_wolf")
      end

      it "does not award lone_wolf if user is in a group" do
        15.times do |i|
          date = challenge.start_date + 5.days + i.days
          reading = create(:reading, challenge: challenge, scheduled_date: date, book_number: 1, chapter_number: i + 1)
          create(:user_reading, user: user, reading: reading, completed_on: date)
        end
        group = create(:group, challenge: challenge)
        create(:user_group_enrollment, user: user, group: group)

        result = BadgeAwarder.new(user, challenge).call
        expect(result).not_to include("lone_wolf")
      end
    end
  end
end
