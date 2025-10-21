# frozen_string_literal: true

class WinnerDrawComponentPreview < ViewComponent::Preview
  # @!group With different numbers of users

  # Small group with 4 participants
  def small_group
    users = create_mock_users(4)
    challenge = create_mock_challenge("Small Challenge")
    render(WinnerDrawComponent.new(users: users, challenge: challenge))
  end

  # Medium group with 10 participants
  def medium_group
    users = create_mock_users(10)
    challenge = create_mock_challenge("Munich Fall Reading Challenge")
    render(WinnerDrawComponent.new(users: users, challenge: challenge))
  end

  # Large group with 20 participants
  def large_group
    users = create_mock_users(20)
    challenge = create_mock_challenge("Large Bible Challenge")
    render(WinnerDrawComponent.new(users: users, challenge: challenge))
  end

  # Extra large group with 25 participants
  def extra_large_group
    users = create_mock_users(25)
    challenge = create_mock_challenge("Extra Large Bible Challenge")
    render(WinnerDrawComponent.new(users: users, challenge: challenge))
  end

  # No users selected
  def no_users
    users = []
    challenge = create_mock_challenge("Empty Challenge")
    render(WinnerDrawComponent.new(users: users, challenge: challenge))
  end

  # @!endgroup

  private

  def create_mock_users(count)
    names = [
      "Alice Johnson", "Bob Smith", "Charlie Brown", "Diana Prince",
      "Edward Norton", "Fiona Apple", "George Michael", "Hannah Montana",
      "Isaac Newton", "Julia Roberts", "Kevin Hart", "Laura Dern",
      "Michael Scott", "Nancy Drew", "Oliver Twist", "Patricia Hill",
      "Quincy Jones", "Rachel Green", "Samuel Jackson", "Teresa May"
    ]

    usernames = [
      "alice", "bob", "charlie", "diana",
      "edward", "fiona", "george", "hannah",
      "isaac", "julia", "kevin", "laura",
      "michael", "nancy", "oliver", "patricia",
      "quincy", "rachel", "samuel", "teresa"
    ]

    count.times.map do |i|
      OpenStruct.new(
        id: i + 1,
        name: names[i % names.length],
        username: usernames[i % usernames.length],
        avatar: OpenStruct.new(attached?: false)
      )
    end
  end

  def create_mock_challenge(title)
    OpenStruct.new(
      id: 1,
      title: title
    )
  end
end
