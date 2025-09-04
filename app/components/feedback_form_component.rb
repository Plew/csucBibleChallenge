# frozen_string_literal: true

class FeedbackFormComponent < ViewComponent::Base
  def initialize(feedback:, form_url:, cancel_url: nil)
    @feedback = feedback
    @form_url = form_url
    @cancel_url = cancel_url || "/"
  end

  private

  attr_reader :feedback, :form_url, :cancel_url

  def category_options
    Feedback.categories.map do |key, value|
      [key.humanize, key]
    end
  end
end