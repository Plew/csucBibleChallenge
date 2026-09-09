# frozen_string_literal: true

class InteractiveReadingDisplayComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(title:, verses: [], current_user: nil, is_completed: true, reading_id: nil)
    @title = title
    @verses = verses
    @current_user = current_user
    @is_completed = is_completed
    @reading_id = reading_id
  end

  private

  attr_reader :title, :verses, :current_user, :is_completed, :reading_id
end
