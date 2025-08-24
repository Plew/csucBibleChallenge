# frozen_string_literal: true

class Statistics::TopGroupsComponentPreview < ViewComponent::Preview
  # Top groups with varying member counts
  def with_groups
    render(Statistics::TopGroupsComponent.new(top_groups_data: sample_top_groups_data))
  end

  # Groups with different member counts to test alignment
  def alignment_test
    render(Statistics::TopGroupsComponent.new(top_groups_data: alignment_test_data))
  end

  # Empty state - no groups
  def empty_state
    render(Statistics::TopGroupsComponent.new(top_groups_data: []))
  end

  private

  def sample_top_groups_data
    [
      {
        group: mock_group("Warriors", 5),
        completion_percentage: 87.5,
        group_size: 5,
        total_chapters_read: 175
      },
      {
        group: mock_group("Disciples", 3),
        completion_percentage: 82.1,
        group_size: 3,
        total_chapters_read: 123
      },
      {
        group: mock_group("Shepherds", 7),
        completion_percentage: 79.3,
        group_size: 7,
        total_chapters_read: 221
      }
    ]
  end

  def alignment_test_data
    [
      {
        group: mock_group("Many Members Group", 8),
        completion_percentage: 95.5,
        group_size: 8,
        total_chapters_read: 320
      },
      {
        group: mock_group("Solo Reader", 1),
        completion_percentage: 92.1,
        group_size: 1,
        total_chapters_read: 41
      },
      {
        group: mock_group("Duo Team", 2),
        completion_percentage: 88.7,
        group_size: 2,
        total_chapters_read: 88
      },
      {
        group: mock_group("Small Group", 3),
        completion_percentage: 85.3,
        group_size: 3,
        total_chapters_read: 127
      }
    ]
  end

  def mock_group(name, member_count)
    users = (1..member_count).map do |i|
      User.new(
        id: "#{name.downcase.gsub(' ', '')}_#{i}".hash.abs,
        username: "user#{i}",
        email: "user#{i}@example.com"
      )
    end

    Group.new(
      id: name.hash.abs,
      name: name,
      users: users
    )
  end
end