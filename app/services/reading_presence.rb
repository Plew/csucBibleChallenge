# frozen_string_literal: true

# Service for tracking active readers on a reading page.
# Uses Redis with automatic expiration for presence tracking.
# Users are considered "active" only while sending heartbeats.
class ReadingPresence
  HEARTBEAT_EXPIRY = 30.seconds
  REDIS_KEY_PREFIX = "reading_presence"

  class << self
    # Record a heartbeat from a user viewing a reading
    def heartbeat(user_id, reading_id)
      redis.setex(
        user_key(user_id, reading_id),
        HEARTBEAT_EXPIRY.to_i,
        Time.current.to_i
      )
      redis.sadd(reading_users_key(reading_id), user_id)
    end

    # Mark a user as inactive (called when they stop interacting)
    def leave(user_id, reading_id)
      redis.del(user_key(user_id, reading_id))
      redis.srem(reading_users_key(reading_id), user_id)
    end

    # Get count of active viewers for a reading
    def active_count(reading_id)
      cleanup_stale_users(reading_id)
      redis.scard(reading_users_key(reading_id))
    end

    # Get list of active user IDs for a reading
    def active_user_ids(reading_id)
      cleanup_stale_users(reading_id)
      redis.smembers(reading_users_key(reading_id)).map(&:to_i)
    end

    # Check if a specific user is active on a reading
    def active?(user_id, reading_id)
      redis.exists?(user_key(user_id, reading_id))
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
      # Generate a consistent color from username
      hue = username.to_s.bytes.sum % 360
      color = "hsl(#{hue}, 65%, 45%)"

      svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
          <rect width="32" height="32" fill="#{color}" rx="16"/>
          <text x="16" y="21" text-anchor="middle" fill="white" font-family="system-ui, sans-serif" font-size="14" font-weight="500">#{initial}</text>
        </svg>
      SVG

      "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
    end

    def redis
      @redis ||= Redis.new(url: redis_url)
    end

    def redis_url
      Rails.application.config_for(:cable)[:url] || "redis://localhost:6379/1"
    end

    def user_key(user_id, reading_id)
      "#{REDIS_KEY_PREFIX}:#{reading_id}:user:#{user_id}"
    end

    def reading_users_key(reading_id)
      "#{REDIS_KEY_PREFIX}:#{reading_id}:users"
    end

    # Remove users from the set whose heartbeat keys have expired
    def cleanup_stale_users(reading_id)
      user_ids = redis.smembers(reading_users_key(reading_id))
      user_ids.each do |user_id|
        unless redis.exists?(user_key(user_id, reading_id))
          redis.srem(reading_users_key(reading_id), user_id)
        end
      end
    end
  end
end
