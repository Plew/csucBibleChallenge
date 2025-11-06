# frozen_string_literal: true

class InteractiveReadingDisplayComponentPreview < ViewComponent::Preview
  def after_reading
    # Create mock users for the chat messages
    user1 = OpenStruct.new(
      id: 1,
      username: "john_doe",
      email: "john@example.com"
    )

    user2 = OpenStruct.new(
      id: 2,
      username: "jane_smith",
      email: "jane@example.com"
    )

    render InteractiveReadingDisplayComponent.new(
      title: "John 3:16-18",
      verses: [
        {
          verse_number: 16,
          verse_text: "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.",
          messages: [
            {
              user: user1,
              content: "This verse is so powerful! It really shows God's love for us.",
              created_at: 2.hours.ago
            },
            {
              user: user2,
              content: "Absolutely! The word 'whoever' is so inclusive - it means everyone.",
              created_at: 1.hour.ago
            }
          ]
        },
        {
          verse_number: 17,
          verse_text: "For God did not send his Son into the world to condemn the world, but in order that the world might be saved through him.",
          messages: [
            {
              user: user1,
              content: "I love this clarification - Jesus came to save, not condemn.",
              created_at: 1.hour.ago
            }
          ]
        },
        {
          verse_number: 18,
          verse_text: "Whoever believes in him is not condemned, but whoever does not believe is condemned already, because he has not believed in the name of the only Son of God.",
          messages: []
        }
      ]
    )
  end

  def empty_verses
    render InteractiveReadingDisplayComponent.new(
      title: "Empty Reading",
      verses: []
    )
  end

  def no_messages
    render InteractiveReadingDisplayComponent.new(
      title: "Romans 8:28",
      verses: [
        {
          verse_number: 28,
          verse_text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose.",
          messages: []
        }
      ]
    )
  end
end
