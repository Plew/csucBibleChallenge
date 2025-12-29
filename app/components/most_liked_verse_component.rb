# frozen_string_literal: true

class MostLikedVerseComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(most_liked_verse:)
    @most_liked_verse = most_liked_verse
  end

  private

  attr_reader :most_liked_verse

  def has_verse?
    most_liked_verse.present?
  end

  def reference
    most_liked_verse[:reference]
  end

  def text
    most_liked_verse[:text]
  end

  def like_count
    most_liked_verse[:like_count]
  end
end
