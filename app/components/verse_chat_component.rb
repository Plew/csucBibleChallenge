# frozen_string_literal: true

class VerseChatComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(verse:, current_user: nil, messages: [])
    @verse = verse
    @current_user = current_user
    @messages = messages
  end

  private

  attr_reader :verse, :current_user, :messages

  def verse_id
    verse.is_a?(Hash) ? verse[:id] : verse.id
  end

  def new_message
    @new_message ||= VerseMessage.new
  end
end
