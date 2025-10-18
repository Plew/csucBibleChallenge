# frozen_string_literal: true

class InteractiveReadingDisplayComponent < ViewComponent::Base
  def initialize(title:, verses: [], current_user: nil)
    @title = title
    @verses = verses
    @current_user = current_user
  end

  private

  attr_reader :title, :verses, :current_user
end
