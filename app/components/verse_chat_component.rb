# frozen_string_literal: true

class VerseChatComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(reading_id:, verse_number:, current_user: nil, messages: [], likers: [])
    @reading_id = reading_id
    @verse_number = verse_number
    @current_user = current_user
    @messages = messages
    @likers = likers
  end

  private

  attr_reader :reading_id, :verse_number, :current_user, :messages, :likers

  def chat_id
    "#{reading_id}-#{verse_number}"
  end

  def new_message
    @new_message ||= VerseMessage.new
  end

  def reading
    @reading ||= Reading.find(reading_id)
  end
end
