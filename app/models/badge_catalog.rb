# frozen_string_literal: true

module BadgeCatalog
  Badge = Data.define(:key, :category, :icon, :threshold, :check_type)

  BADGES = [
    Badge.new(key: "chapters_50", category: "chapters", icon: "book", threshold: 50, check_type: :chapters),
    Badge.new(key: "chapters_100", category: "chapters", icon: "book", threshold: 100, check_type: :chapters),
    Badge.new(key: "streak_7", category: "streak", icon: "fire", threshold: 7, check_type: :streak),
    Badge.new(key: "streak_30", category: "streak", icon: "fire", threshold: 30, check_type: :streak),
    Badge.new(key: "streak_50", category: "streak", icon: "fire", threshold: 50, check_type: :streak),
Badge.new(key: "verse_lover", category: "social", icon: "heart", threshold: 20, check_type: :verse_likes),
    Badge.new(key: "crack_of_dawn", category: "fun", icon: "sunrise", threshold: 10, check_type: :early_reading),
    Badge.new(key: "go_to_bed", category: "fun", icon: "moon", threshold: 10, check_type: :late_reading),
    Badge.new(key: "just_barely", category: "fun", icon: "sweat", threshold: 1, check_type: :last_minute),
    Badge.new(key: "slightly_sus", category: "fun", icon: "eyes", threshold: 10, check_type: :bulk_reading),
    Badge.new(key: "i_have_returned", category: "fun", icon: "wave", threshold: 10, check_type: :returned),
    Badge.new(key: "lone_wolf", category: "fun", icon: "wolf", threshold: 15, check_type: :lone_wolf),
    Badge.new(key: "weekend_warrior", category: "fun", icon: "flex", threshold: 8, check_type: :weekend_warrior),
    Badge.new(key: "catch_up_king", category: "fun", icon: "runner", threshold: 20, check_type: :catch_up),
    Badge.new(key: "halfway_there", category: "chapters", icon: "flag", threshold: 50, check_type: :completion_pct),
    Badge.new(key: "chatty_chapter", category: "fun", icon: "speech", threshold: 5, check_type: :chatty_chapter),
    Badge.new(key: "love_is_not_cheap", category: "fun", icon: "diamond", threshold: 5, check_type: :picky_liker),
    Badge.new(key: "conversation_starter", category: "fun", icon: "megaphone", threshold: 5, check_type: :conversation_starter)
  ].freeze

  BADGE_MAP = BADGES.index_by(&:key).freeze

  def self.all
    BADGES
  end

  def self.find(key)
    BADGE_MAP[key.to_s]
  end

  def self.by_category(category)
    BADGES.select { |b| b.category == category.to_s }
  end

  def self.keys
    BADGE_MAP.keys
  end

  def self.categories
    BADGES.map(&:category).uniq
  end
end
