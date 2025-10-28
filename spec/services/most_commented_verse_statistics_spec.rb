# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MostCommentedVerseStatistics do
  include ActiveSupport::Testing::TimeHelpers

  let(:timezone) { 'UTC' }
  let(:challenge) { create(:challenge, timezone: timezone) }
  let(:reading) { create(:reading, challenge: challenge, scheduled_date: Date.current) }
  let(:user) { create(:user) }

  describe '#most_commented_verse_today' do
    context 'when there are verse messages today' do
      before do
        # Create verse messages for different verses
        5.times { create(:verse_message, reading: reading, verse_number: 1, user: user) }
        3.times { create(:verse_message, reading: reading, verse_number: 2, user: user) }
        8.times { create(:verse_message, reading: reading, verse_number: 3, user: user) }
      end

      it 'returns the verse with the most comments' do
        statistics = described_class.new(challenge)
        result = statistics.most_commented_verse_today

        expect(result).not_to be_nil
        expect(result[:verse_number]).to eq(3)
        expect(result[:comment_count]).to eq(8)
      end

      it 'includes verse details' do
        statistics = described_class.new(challenge)
        result = statistics.most_commented_verse_today

        expect(result[:reading]).to eq(reading)
        expect(result[:book_name]).to be_present
        expect(result[:chapter_number]).to eq(reading.chapter_number)
      end
    end

    context 'when there are no verse messages today' do
      it 'returns nil' do
        statistics = described_class.new(challenge)
        result = statistics.most_commented_verse_today

        expect(result).to be_nil
      end
    end

    context 'when verse messages are from previous days' do
      before do
        travel_to(1.day.ago) do
          5.times { create(:verse_message, reading: reading, verse_number: 1, user: user) }
        end
      end

      it 'returns nil' do
        statistics = described_class.new(challenge)
        result = statistics.most_commented_verse_today

        expect(result).to be_nil
      end
    end
  end

  describe '#total_comments_today' do
    context 'when there are verse messages today' do
      before do
        5.times { create(:verse_message, reading: reading, verse_number: 1, user: user) }
        3.times { create(:verse_message, reading: reading, verse_number: 2, user: user) }
      end

      it 'returns the total count of comments' do
        statistics = described_class.new(challenge)
        expect(statistics.total_comments_today).to eq(8)
      end
    end

    context 'when there are no verse messages today' do
      it 'returns 0' do
        statistics = described_class.new(challenge)
        expect(statistics.total_comments_today).to eq(0)
      end
    end
  end

  describe '#most_commented_verse_for_date' do
    let(:past_date) { 3.days.ago.to_date }
    let(:past_reading) { create(:reading, challenge: challenge, scheduled_date: past_date) }

    context 'when there are verse messages on the specified date' do
      before do
        travel_to(past_date) do
          4.times { create(:verse_message, reading: past_reading, verse_number: 5, user: user) }
          2.times { create(:verse_message, reading: past_reading, verse_number: 6, user: user) }
        end
      end

      it 'returns the most commented verse for that date' do
        statistics = described_class.new(challenge)
        result = statistics.most_commented_verse_for_date(past_date)

        expect(result).not_to be_nil
        expect(result[:verse_number]).to eq(5)
        expect(result[:comment_count]).to eq(4)
      end
    end
  end
end
