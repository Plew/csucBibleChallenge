# frozen_string_literal: true

class Statistics::TopReadersComponent < ViewComponent::Base
  DISPLAY_LIMIT = 7

  def initialize(top_readers_data:, show_all: false)
    @top_readers_data = top_readers_data
    @show_all = show_all
  end

  private

  attr_reader :top_readers_data, :show_all

  def has_readers?
    top_readers_data.any?
  end

  def reader_count
    top_readers_data.length
  end

  def displayed_readers
    show_all ? top_readers_data : top_readers_data.first(DISPLAY_LIMIT)
  end

  def has_more_readers?
    !show_all && reader_count > DISPLAY_LIMIT
  end

  def rank_color(rank)
    case rank
    when 1 then "text-yellow-400 bg-yellow-400/20"
    when 2 then "text-gray-300 bg-gray-300/20"
    when 3 then "text-orange-400 bg-orange-400/20"
    else "text-base-content/40"
    end
  end

  def top_three?(rank)
    rank <= 3
  end

  def avatar_fallback_initials(user)
    user.username.first.upcase
  end
end
