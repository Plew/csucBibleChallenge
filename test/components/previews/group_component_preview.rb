class GroupComponentPreview < ViewComponent::Preview
  # Default group view (non-member viewing)
  # @label Default (Non-member)
  def default
    group = create_sample_group
    current_user = User.new(id: 999, username: "visitor", email: "visitor@example.com")

    render GroupComponent.new(
      group: group,
      current_user: current_user,
      user_group: nil
    )
  end

  # Group member view (joined)
  # @label Member View
  def member_view
    group = create_sample_group
    current_user = group.users.second # Use second user (not the creator)

    render GroupComponent.new(
      group: group,
      current_user: current_user,
      user_group: group
    )
  end

  # Group creator view
  # @label Creator View
  def creator_view
    group = create_sample_group
    current_user = group.creator

    render GroupComponent.new(
      group: group,
      current_user: current_user,
      user_group: group
    )
  end

  # Group with motto
  # @label With Motto
  def with_motto
    group = create_sample_group(motto: "Reading together, growing together")
    current_user = group.users.second # Use second user (not the creator)

    render GroupComponent.new(
      group: group,
      current_user: current_user,
      user_group: group
    )
  end

  # Closed group
  # @label Closed Group
  def closed_group
    group = create_sample_group(closed_to_new_members: true)
    current_user = User.new(id: 999, username: "visitor", email: "visitor@example.com")

    render GroupComponent.new(
      group: group,
      current_user: current_user,
      user_group: nil
    )
  end

  # Large group with many members
  # @label Large Group
  def large_group
    group = create_sample_group(member_count: 12)
    current_user = group.users.second # Use second user (not the creator)

    render GroupComponent.new(
      group: group,
      current_user: current_user,
      user_group: group
    )
  end

  private

  def create_sample_group(motto: nil, closed_to_new_members: false, member_count: 5)
    # Create today's reading
    todays_reading = Reading.new(
      id: 1,
      scheduled_date: Date.current,
      book_number: 1,
      chapter_number: 1
    )

    challenge = Challenge.new(
      id: 1,
      name: "30 Day Challenge",
      description: "Read the Bible in 30 days",
      timezone: "America/New_York"
    )

    # Mock challenge.readings to return today's reading
    challenge.define_singleton_method(:readings) do
      mock_readings = Object.new
      mock_readings.define_singleton_method(:find_by) { |args| todays_reading if args[:scheduled_date] == Date.current }
      mock_readings
    end

    creator = User.new(
      id: 1,
      username: "GroupLeader",
      email: "leader@example.com"
    )

    # Create additional members
    members = [ creator ]
    (member_count - 1).times do |i|
      members << User.new(
        id: i + 2,
        username: "Member#{i + 1}",
        email: "member#{i + 1}@example.com"
      )
    end

    # Mock user_readings to simulate some members have read today
    members.each_with_index do |user, index|
      # First 3 members have read today (creator + 2 members)
      has_read = index < 3

      user.define_singleton_method(:user_readings) do
        mock_user_readings = Object.new
        mock_user_readings.define_singleton_method(:exists?) do |args|
          has_read && args[:reading_id] == todays_reading.id
        end
        mock_user_readings
      end
    end

    group = Group.new(
      id: 1,
      name: "Bible Study Group",
      motto: motto,
      closed_to_new_members: closed_to_new_members,
      challenge: challenge,
      creator: creator,
      token: "ABC123"
    )

    # Mock associations
    group.define_singleton_method(:users) { members }

    # Mock user_group_enrollments for displaying members
    enrollments = members.map.with_index do |user, index|
      enrollment = UserGroupEnrollment.new(
        id: index + 1,
        user: user,
        group: group
      )
      # Make sure enrollment.user returns the user
      enrollment.define_singleton_method(:user) { user }
      enrollment
    end

    group.define_singleton_method(:user_group_enrollments) do
      mock_relation = Object.new
      mock_relation.define_singleton_method(:includes) { |*args| mock_relation }
      mock_relation.define_singleton_method(:each) { |&block| enrollments.each(&block) }
      mock_relation.define_singleton_method(:find) { |&block| enrollments.find(&block) }
      mock_relation.define_singleton_method(:reject) { |&block| enrollments.reject(&block) }
      mock_relation.define_singleton_method(:compact) { enrollments.compact }
      mock_relation
    end

    group
  end
end
