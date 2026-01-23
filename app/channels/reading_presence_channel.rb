# frozen_string_literal: true

# ActionCable channel for tracking active readers on a reading page.
# Handles heartbeat pings from active users and broadcasts viewer counts.
class ReadingPresenceChannel < ApplicationCable::Channel
  def subscribed
    @reading_id = params[:reading_id]

    return reject unless @reading_id.present?

    stream_from stream_name

    # Record initial presence
    ReadingPresence.heartbeat(current_user.id, @reading_id)
    broadcast_viewer_count
  end

  def unsubscribed
    return unless @reading_id.present?

    ReadingPresence.leave(current_user.id, @reading_id)
    broadcast_viewer_count
  end

  # Called by client when user is actively engaged (scrolling, clicking, etc.)
  def heartbeat
    return unless @reading_id.present?

    ReadingPresence.heartbeat(current_user.id, @reading_id)
    broadcast_viewer_count
  end

  # Called by client when user becomes inactive (60s without activity)
  def inactive
    return unless @reading_id.present?

    ReadingPresence.leave(current_user.id, @reading_id)
    broadcast_viewer_count
  end

  private

  def stream_name
    "reading_#{@reading_id}_presence"
  end

  def broadcast_presence
    users = ReadingPresence.active_users_data(@reading_id)
    ActionCable.server.broadcast(
      stream_name,
      { type: "presence_update", users: users }
    )
  end

  # Keep for backwards compatibility
  def broadcast_viewer_count
    broadcast_presence
  end
end
