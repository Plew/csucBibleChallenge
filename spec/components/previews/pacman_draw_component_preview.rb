# frozen_string_literal: true

class PacmanDrawComponentPreview < ViewComponent::Preview
  # Shows the Pac-Man draw with 8 ghosts
  # @label With 8 Ghosts
  def default
    challenge = Challenge.first || FactoryBot.create(:challenge)
    users = User.left_joins(:avatar_attachment).where(active_storage_attachments: { id: nil }).limit(8)
    users = users.presence || User.limit(8)

    render PacmanDrawComponent.new(users: users, challenge: challenge)
  end

  # Shows the Pac-Man draw with 3 ghosts (quicker animation)
  # @label With 3 Ghosts (Quick)
  def three_ghosts
    challenge = Challenge.first || FactoryBot.create(:challenge)
    users = User.left_joins(:avatar_attachment).where(active_storage_attachments: { id: nil }).limit(3)
    users = users.presence || User.limit(3)

    render PacmanDrawComponent.new(users: users, challenge: challenge)
  end

  # Shows the Pac-Man draw with 5 ghosts
  # @label With 5 Ghosts
  def five_ghosts
    challenge = Challenge.first || FactoryBot.create(:challenge)
    users = User.left_joins(:avatar_attachment).where(active_storage_attachments: { id: nil }).limit(5)
    users = users.presence || User.limit(5)

    render PacmanDrawComponent.new(users: users, challenge: challenge)
  end

  # Shows the component with no users (empty state)
  # @label No Users (Empty State)
  def no_users
    challenge = Challenge.first || FactoryBot.create(:challenge)

    render PacmanDrawComponent.new(users: [], challenge: challenge)
  end

  # Shows the Pac-Man draw with 30 ghosts (large group)
  # @label With 30 Ghosts (Large)
  def thirty_ghosts
    challenge = Challenge.first || FactoryBot.create(:challenge)
    users = User.limit(30)

    render PacmanDrawComponent.new(users: users, challenge: challenge)
  end

  # Shows the Pac-Man draw with 45 ghosts (extra large group)
  # @label With 45 Ghosts (XL)
  def forty_five_ghosts
    challenge = Challenge.first || FactoryBot.create(:challenge)
    users = User.limit(45)

    render PacmanDrawComponent.new(users: users, challenge: challenge)
  end
end
