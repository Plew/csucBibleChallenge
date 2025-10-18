# frozen_string_literal: true

class ChapterChatComponentPreview < ViewComponent::Preview

  def default
    group = create_sample_group
    current_user = group.users.first
    user_group = group

    # Create some sample messages
    other_user = group.users.second
    group.group_messages.create!(
      user: current_user,
      content: "What did you think of this chapter?",
      created_at: 2.hours.ago
    )
    group.group_messages.create!(
      user: other_user,
      content: "Really powerful! The part about faith really spoke to me.",
      created_at: 1.hour.ago
    )
    group.group_messages.create!(
      user: current_user,
      content: "Same here! Verse 12 was especially meaningful.",
      created_at: 30.minutes.ago
    )

    render ChapterChatComponent.new(
      group: group,
      current_user: current_user,
      user_group: user_group
    )
  end

  def empty_chat
    group = create_sample_group
    current_user = group.users.first
    user_group = group

    render ChapterChatComponent.new(
      group: group,
      current_user: current_user,
      user_group: user_group
    )
  end

  def non_member
    group = create_sample_group
    current_user = User.new(id: 999, username: "outsider", email: "outsider@example.com")
    user_group = nil

    render ChapterChatComponent.new(
      group: group,
      current_user: current_user,
      user_group: user_group
    )
  end

  private

  def create_sample_group
    challenge = Challenge.new(
      id: 1,
      name: "30 Day Challenge",
      description: "Read the Bible in 30 days",
      timezone: "America/New_York"
    )

    creator = User.new(
      id: 1,
      username: "john_doe",
      email: "john@example.com"
    )

    member = User.new(
      id: 2,
      username: "jane_smith",
      email: "jane@example.com"
    )

    group = Group.new(
      id: 1,
      name: "Morning Readers",
      challenge: challenge,
      creator: creator
    )

    # Mock associations
    group.define_singleton_method(:users) { [creator, member] }
    group.define_singleton_method(:group_messages) do
      @group_messages ||= Class.new do
        def initialize
          @created_messages = []
        end

        def create!(**attrs)
          message = GroupMessage.new(attrs.merge(id: rand(1000)))
          @created_messages << message
          message
        end

        def includes(*args)
          self
        end

        def order(*args)
          self
        end

        def limit(*args)
          @created_messages
        end

        def method_missing(method, *args, &block)
          # Return self for chainable ActiveRecord methods, or the array for others
          if [:includes, :order, :where, :joins].include?(method)
            self
          else
            @created_messages.send(method, *args, &block)
          end
        end

        def respond_to_missing?(method, include_private = false)
          @created_messages.respond_to?(method, include_private) || super
        end

        def any?
          @created_messages.any?
        end

        def each(&block)
          @created_messages.each(&block)
        end
      end.new
    end

    group
  end
end
