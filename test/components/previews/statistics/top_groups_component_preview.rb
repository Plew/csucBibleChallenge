# frozen_string_literal: true

class Statistics::TopGroupsComponentPreview < ViewComponent::Preview
  # Top groups with full data
  def with_groups
    render(Statistics::TopGroupsComponent.new(top_groups_data: sample_top_groups_data))
  end

  # Empty state - no groups
  def empty_state
    render(Statistics::TopGroupsComponent.new(top_groups_data: []))
  end

  # Single group
  def single_group
    render(Statistics::TopGroupsComponent.new(top_groups_data: sample_top_groups_data.first(1)))
  end

  private

  def sample_top_groups_data
    [
      {
        group: mock_group("The Faithful Five", "bible_champions"),
        completion_percentage: 92.4,
        members: [
          { username: "alice", avatar_url: "https://ui-avatars.com/api/?name=Alice&background=3b82f6&color=fff" },
          { username: "bob", avatar_url: nil },
          { username: "charlie", avatar_url: "https://ui-avatars.com/api/?name=Charlie&background=10b981&color=fff" },
          { username: "diana", avatar_url: nil },
          { username: "eve", avatar_url: "https://ui-avatars.com/api/?name=Eve&background=f59e0b&color=fff" }
        ]
      },
      {
        group: mock_group("Scripture Seekers", "word_warriors"),
        completion_percentage: 87.8,
        members: [
          { username: "frank", avatar_url: "https://ui-avatars.com/api/?name=Frank&background=8b5cf6&color=fff" },
          { username: "grace", avatar_url: nil },
          { username: "henry", avatar_url: "https://ui-avatars.com/api/?name=Henry&background=06b6d4&color=fff" }
        ]
      },
      {
        group: mock_group("Daily Devotion Squad", "devotion_team"),
        completion_percentage: 81.3,
        members: [
          { username: "ivy", avatar_url: nil },
          { username: "jack", avatar_url: "https://ui-avatars.com/api/?name=Jack&background=ef4444&color=fff" },
          { username: "kate", avatar_url: nil },
          { username: "liam", avatar_url: "https://ui-avatars.com/api/?name=Liam&background=22c55e&color=fff" },
          { username: "mia", avatar_url: nil },
          { username: "noah", avatar_url: "https://ui-avatars.com/api/?name=Noah&background=f97316&color=fff" },
          { username: "olivia", avatar_url: nil }
        ]
      },
      {
        group: mock_group("Grace & Truth", "grace_truth"),
        completion_percentage: 76.5,
        members: [
          { username: "paul", avatar_url: "https://ui-avatars.com/api/?name=Paul&background=ec4899&color=fff" },
          { username: "quinn", avatar_url: nil }
        ]
      },
      {
        group: mock_group("Bible Study Buddies", "study_buddies"),
        completion_percentage: 69.2,
        members: [
          { username: "ryan", avatar_url: nil },
          { username: "sara", avatar_url: "https://ui-avatars.com/api/?name=Sara&background=84cc16&color=fff" },
          { username: "tom", avatar_url: nil },
          { username: "uma", avatar_url: "https://ui-avatars.com/api/?name=Uma&background=6366f1&color=fff" }
        ]
      }
    ]
  end

  def mock_group(name, slug)
    Group.new(
      id: slug.hash.abs,
      name: name
    )
  end
end