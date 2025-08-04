# frozen_string_literal: true

class ChallengeFormComponent < ViewComponent::Base
  def initialize(
    challenge:,
    bible_books:,
    form_url:,
    cancel_url: nil
  )
    @challenge = challenge
    @bible_books = bible_books
    @form_url = form_url
    @cancel_url = cancel_url || "/"
  end

  private

  attr_reader :challenge, :bible_books, :form_url, :cancel_url

  def timezone_options
    ActiveSupport::TimeZone.all.map { |tz| [tz.name, tz.name] }
  end

  def default_timezone
    Time.zone.name
  end

  def old_testament_books
    bible_books.select { |book| book[:testament] == 'old' }
  end

  def new_testament_books
    bible_books.select { |book| book[:testament] == 'new' }
  end
end