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
    options = ActiveSupport::TimeZone.all.map { |tz| [tz.name, tz.name] }
    
    # Add Munich as an option that maps to Berlin timezone
    berlin_tz = ActiveSupport::TimeZone['Berlin']
    if berlin_tz
      options << ['Munich', berlin_tz.name]
    end
    
    # Sort alphabetically for better UX
    options.sort_by(&:first)
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