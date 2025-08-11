# frozen_string_literal: true

class Statistics::TopReadersComponentPreview < ViewComponent::Preview
  # Top readers with full data
  def with_readers
    render(Statistics::TopReadersComponent.new(top_readers_data: sample_top_readers_data))
  end

  # Empty state - no readers
  def empty_state
    render(Statistics::TopReadersComponent.new(top_readers_data: []))
  end

  # Single reader
  def single_reader
    render(Statistics::TopReadersComponent.new(top_readers_data: sample_top_readers_data.first(1)))
  end

  private

  def sample_top_readers_data
    [
      {
        user: mock_user("alice", "Alice Johnson"),
        total_chapters_read: 43,
        chapters_completed: 43,
        chapters_scheduled: 45,
        completion_percentage: 95.6,
        avatar_url: "https://ui-avatars.com/api/?name=Alice+Johnson&background=3b82f6&color=fff"
      },
      {
        user: mock_user("bob", "Bob Smith"),
        total_chapters_read: 39,
        chapters_completed: 39,
        chapters_scheduled: 45,
        completion_percentage: 86.7,
        avatar_url: nil
      },
      {
        user: mock_user("charlie", "Charlie Brown"),
        total_chapters_read: 35,
        chapters_completed: 35,
        chapters_scheduled: 45,
        completion_percentage: 77.8,
        avatar_url: "https://ui-avatars.com/api/?name=Charlie+Brown&background=10b981&color=fff"
      },
      {
        user: mock_user("diana", "Diana Prince"),
        total_chapters_read: 32,
        chapters_completed: 32,
        chapters_scheduled: 45,
        completion_percentage: 71.1,
        avatar_url: nil
      },
      {
        user: mock_user("eve", "Eve Adams"),
        total_chapters_read: 28,
        chapters_completed: 28,
        chapters_scheduled: 45,
        completion_percentage: 62.2,
        avatar_url: "https://ui-avatars.com/api/?name=Eve+Adams&background=f59e0b&color=fff"
      }
    ]
  end

  def mock_user(username, display_name)
    User.new(
      id: username.hash.abs,
      username: username,
      email: "#{username}@example.com"
    )
  end
end