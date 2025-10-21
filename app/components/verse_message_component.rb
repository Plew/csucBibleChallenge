# frozen_string_literal: true

class VerseMessageComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(message:, current_user:, reading:, verse_number:)
    @message = message
    @current_user = current_user
    @reading = reading
    @verse_number = verse_number
  end

  private

  attr_reader :message, :current_user, :reading, :verse_number

  def is_own_message?
    current_user && message.user_id == current_user.id
  end
end
