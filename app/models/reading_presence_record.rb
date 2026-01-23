# frozen_string_literal: true

# Tracks active users viewing a reading page.
# Used by ReadingPresence service for presence tracking.
class ReadingPresenceRecord < ApplicationRecord
  self.table_name = "reading_presences"

  belongs_to :user, optional: true
  belongs_to :reading, optional: true

  HEARTBEAT_EXPIRY = 30.seconds

  scope :active, -> { where("last_heartbeat_at > ?", HEARTBEAT_EXPIRY.ago) }
  scope :for_reading, ->(reading_id) { where(reading_id: reading_id) }

  # Record or update a heartbeat for a user on a reading
  def self.heartbeat(user_id, reading_id)
    record = find_or_initialize_by(user_id: user_id, reading_id: reading_id)
    record.update!(last_heartbeat_at: Time.current)
  end

  # Remove a user's presence record
  def self.leave(user_id, reading_id)
    where(user_id: user_id, reading_id: reading_id).delete_all
  end

  # Get count of active users for a reading
  def self.active_count(reading_id)
    for_reading(reading_id).active.count
  end

  # Get active user IDs for a reading
  def self.active_user_ids(reading_id)
    for_reading(reading_id).active.pluck(:user_id)
  end

  # Check if a user is active on a reading
  def self.active?(user_id, reading_id)
    for_reading(reading_id).active.exists?(user_id: user_id)
  end

  # Clean up stale presence records (older than expiry)
  def self.cleanup_stale
    where("last_heartbeat_at <= ?", HEARTBEAT_EXPIRY.ago).delete_all
  end
end
