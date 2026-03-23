# frozen_string_literal: true

class Statistics::MostLikedVersesTodayComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(most_liked_verse_today:)
    @most_liked_verse_today = most_liked_verse_today || []
  end

  private

  attr_reader :most_liked_verse_today

  def verse_count
    most_liked_verse_today.length
  end

  def preview_text
    t("stats.most_liked_verses_count", count: verse_count)
  end
end
