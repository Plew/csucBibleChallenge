# frozen_string_literal: true

# Service for tracking active readers on a reading page.
# Uses SQLite database with automatic expiration for presence tracking.
# Users are considered "active" only while sending heartbeats.
class ReadingPresence
  HEARTBEAT_EXPIRY = 30.seconds
  AVATAR_PALETTE = [
    "#6B7558", # Muted Olive (Theme Primary)
    "#C79C46", # Mustard Gold (Theme Secondary / Warning)
    "#4A6B82", # Muted Slate Blue (Theme Info)
    "#B05858", # Terracotta Rust (Theme Error)
    "#556E3F", # Forest Green (Theme Success)
    "#4F5D95", # Dusty Indigo
    "#8B5A7E", # Warm Plum
    "#2E7977", # Deep Teal
    "#BD5A38", # Rust Orange
    "#3D7896", # Soft Ocean Blue
    "#87533E", # Warm Cedar
    "#A8536E", # Dusty Rose
    "#8A6B3D", # Rich Bronze
    "#3E6953", # Forest Pine
    "#38526F", # Slate Navy
    "#7A4B6B"  # Warm Mulberry
  ].freeze

  class << self
    # Record a heartbeat from a user viewing a reading
    def heartbeat(user_id, reading_id)
      ReadingPresenceRecord.heartbeat(user_id, reading_id)
    end

    # Mark a user as inactive (called when they stop interacting)
    def leave(user_id, reading_id)
      ReadingPresenceRecord.leave(user_id, reading_id)
    end

    # Get count of active viewers for a reading
    def active_count(reading_id)
      ReadingPresenceRecord.active_count(reading_id)
    end

    # Get list of active user IDs for a reading
    def active_user_ids(reading_id)
      ReadingPresenceRecord.active_user_ids(reading_id)
    end

    # Check if a specific user is active on a reading
    def active?(user_id, reading_id)
      ReadingPresenceRecord.active?(user_id, reading_id)
    end

    # Get active users with their avatar URLs for broadcasting
    def active_users_data(reading_id)
      user_ids = active_user_ids(reading_id)
      return [] if user_ids.empty?

      User.where(id: user_ids).map do |user|
        {
          id: user.id,
          username: user.username,
          avatar_url: avatar_url_for(user)
        }
      end
    end

    def color_for_username(username)
      hash = username.to_s.each_byte.reduce(5381) { |h, b| ((h << 5) + h + b) & 0xFFFFFFFF }
      AVATAR_PALETTE[hash % AVATAR_PALETTE.length]
    end

    private

    def avatar_url_for(user)
      if user.avatar.attached?
        Rails.application.routes.url_helpers.rails_blob_path(
          user.avatar.variant(:thumb),
          only_path: true
        )
      else
        # Generate a simple SVG avatar with user's initial and a color based on username
        generate_placeholder_avatar(user.username)
      end
    end

    def generate_placeholder_avatar(username)
      initial = username.to_s[0]&.upcase || "?"
      color = color_for_username(username)

      svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
          <rect width="32" height="32" fill="#{color}" rx="16"/>
          <text x="16" y="21" text-anchor="middle" fill="white" font-family="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" font-weight="600">#{initial}</text>
        </svg>
      SVG

      "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
    end
  end
end
