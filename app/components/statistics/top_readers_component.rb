# frozen_string_literal: true

class Statistics::TopReadersComponent < ViewComponent::Base
  def initialize(top_readers_data:)
    @top_readers_data = top_readers_data
  end

  private

  attr_reader :top_readers_data

  def has_readers?
    top_readers_data.any?
  end

  def reader_count
    top_readers_data.length
  end

  def avatar_fallback_initials(user)
    user.username.first.upcase
  end
end