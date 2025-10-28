# frozen_string_literal: true

class MostCommentedVerseComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(challenge:, statistics: nil)
    @challenge = challenge
    @statistics = statistics || (challenge.is_a?(Challenge) ? MostCommentedVerseStatistics.new(challenge) : MockStatistics.new(challenge))
  end

  private

  attr_reader :challenge, :statistics

  def most_commented_verse
    @most_commented_verse ||= statistics.most_commented_verse_today
  end

  def total_comments
    @total_comments ||= statistics.total_comments_today
  end

  def verse_reference
    return nil unless most_commented_verse
    "#{most_commented_verse[:book_name]} #{most_commented_verse[:chapter_number]}:#{most_commented_verse[:verse_number]}"
  end

  def verse_text
    return nil unless most_commented_verse && most_commented_verse[:verse]
    most_commented_verse[:verse].verse_text
  end

  def comment_count
    return 0 unless most_commented_verse
    most_commented_verse[:comment_count]
  end

  def has_comments?
    most_commented_verse.present?
  end

  # Mock statistics class for preview/testing
  class MockStatistics
    def most_commented_verse_today
      {
        reading: OpenStruct.new(
          book_name: "John",
          chapter_number: 3,
          book_number: 43,
          challenge: OpenStruct.new(name: "Gospel Journey")
        ),
        verse: OpenStruct.new(
          verse_text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
          verse_number: 16
        ),
        verse_number: 16,
        comment_count: 23,
        book_name: "John",
        chapter_number: 3
      }
    end

    def total_comments_today
      42
    end
  end
end
