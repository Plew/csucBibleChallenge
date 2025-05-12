# frozen_string_literal: true

class ReadingDisplayComponent < ViewComponent::Base
  def initialize(title:, verses: [])
    @title = title
    @verses = verses
  end
end 