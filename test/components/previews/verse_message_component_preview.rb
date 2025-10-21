# frozen_string_literal: true

class VerseMessageComponentPreview < ViewComponent::Preview
  # @label Own Message (with delete button)
  def own_message
    user = User.new(id: 1, username: "CurrentUser")
    message = VerseMessage.new(
      id: 1,
      content: "This is my own comment on this verse. I should see a delete button!",
      created_at: 2.hours.ago,
      user: user,
      user_id: user.id
    )
    reading = Reading.new(id: 1)

    render(VerseMessageComponent.new(
      message: message,
      current_user: user,
      reading: reading,
      verse_number: 5
    ))
  end

  # @label Other User's Message (no delete button)
  def other_user_message
    other_user = User.new(id: 2, username: "OtherUser")
    current_user = User.new(id: 1, username: "CurrentUser")
    message = VerseMessage.new(
      id: 2,
      content: "This is someone else's comment. I should NOT see a delete button.",
      created_at: 1.day.ago,
      user: other_user,
      user_id: other_user.id
    )
    reading = Reading.new(id: 1)

    render(VerseMessageComponent.new(
      message: message,
      current_user: current_user,
      reading: reading,
      verse_number: 5
    ))
  end

  # @label Long Message (own)
  def long_own_message
    user = User.new(id: 1, username: "CurrentUser")
    message = VerseMessage.new(
      id: 3,
      content: "This is a much longer comment that spans multiple lines. It demonstrates how the delete button should appear even with longer content. The button should stay at the top right and not interfere with the message content.",
      created_at: 30.minutes.ago,
      user: user,
      user_id: user.id
    )
    reading = Reading.new(id: 1)

    render(VerseMessageComponent.new(
      message: message,
      current_user: user,
      reading: reading,
      verse_number: 5
    ))
  end

  # @label No Current User (guest view)
  def guest_view
    other_user = User.new(id: 2, username: "SomeUser")
    message = VerseMessage.new(
      id: 4,
      content: "A guest viewing this should not see any delete button.",
      created_at: 5.hours.ago,
      user: other_user,
      user_id: other_user.id
    )
    reading = Reading.new(id: 1)

    render(VerseMessageComponent.new(
      message: message,
      current_user: nil,
      reading: reading,
      verse_number: 5
    ))
  end
end
