# frozen_string_literal: true

class ChallengeFormComponentPreview < ViewComponent::Preview
  def default
    render ChallengeFormComponent.new(
      challenge: sample_challenge,
      bible_books: sample_bible_books,
      form_url: "/admin/challenges",
      cancel_url: "/"
    )
  end

  def with_errors
    challenge = sample_challenge_with_errors
    
    render ChallengeFormComponent.new(
      challenge: challenge,
      bible_books: sample_bible_books,
      form_url: "/admin/challenges",
      cancel_url: "/"
    )
  end

  def mobile_view
    render ChallengeFormComponent.new(
      challenge: sample_challenge,
      bible_books: sample_bible_books,
      form_url: "/admin/challenges",
      cancel_url: "/"
    )
  end

  private

  def sample_challenge
    # Use a simple OpenStruct instead of the Challenge model
    OpenStruct.new(
      name: "Sample Reading Challenge",
      start_date: Date.current + 1.day,
      timezone: "UTC",
      errors: MockErrors.new
    )
  end

  def sample_challenge_with_errors
    challenge = sample_challenge
    challenge.errors.add(:name, "can't be blank")
    challenge.errors.add(:start_date, "must be in the future")
    challenge
  end

  def sample_bible_books
    [
      # Old Testament samples
      { number: 1, key: 'genesis', name: 'Genesis', chapters: 50, testament: 'old' },
      { number: 2, key: 'exodus', name: 'Exodus', chapters: 40, testament: 'old' },
      { number: 3, key: 'leviticus', name: 'Leviticus', chapters: 27, testament: 'old' },
      { number: 4, key: 'numbers', name: 'Numbers', chapters: 36, testament: 'old' },
      { number: 5, key: 'deuteronomy', name: 'Deuteronomy', chapters: 34, testament: 'old' },
      { number: 6, key: 'joshua', name: 'Joshua', chapters: 24, testament: 'old' },
      { number: 7, key: 'judges', name: 'Judges', chapters: 21, testament: 'old' },
      { number: 8, key: 'ruth', name: 'Ruth', chapters: 4, testament: 'old' },
      { number: 9, key: 'first_samuel', name: '1 Samuel', chapters: 31, testament: 'old' },
      { number: 10, key: 'second_samuel', name: '2 Samuel', chapters: 24, testament: 'old' },
      
      # New Testament samples  
      { number: 40, key: 'matthew', name: 'Matthew', chapters: 28, testament: 'new' },
      { number: 41, key: 'mark', name: 'Mark', chapters: 16, testament: 'new' },
      { number: 42, key: 'luke', name: 'Luke', chapters: 24, testament: 'new' },
      { number: 43, key: 'john', name: 'John', chapters: 21, testament: 'new' },
      { number: 44, key: 'acts', name: 'Acts', chapters: 28, testament: 'new' },
      { number: 45, key: 'romans', name: 'Romans', chapters: 16, testament: 'new' },
      { number: 46, key: 'first_corinthians', name: '1 Corinthians', chapters: 16, testament: 'new' },
      { number: 47, key: 'second_corinthians', name: '2 Corinthians', chapters: 13, testament: 'new' },
      { number: 48, key: 'galatians', name: 'Galatians', chapters: 6, testament: 'new' },
      { number: 49, key: 'ephesians', name: 'Ephesians', chapters: 6, testament: 'new' }
    ]
  end

  # Simple mock for errors
  class MockErrors
    def initialize
      @errors = {}
    end

    def add(field, message)
      @errors[field] ||= []
      @errors[field] << message
    end

    def any?
      @errors.any?
    end

    def full_messages
      @errors.values.flatten
    end
  end
end