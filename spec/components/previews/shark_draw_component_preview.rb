# frozen_string_literal: true

class SharkDrawComponentPreview < ViewComponent::Preview
  # Shows the shark draw with 8 swimmers
  # @label With 8 Swimmers
  def default
    challenge = Challenge.first || FactoryBot.create(:challenge)
    # Use users without avatars to avoid ActiveStorage file not found errors
    users = User.left_joins(:avatar_attachment).where(active_storage_attachments: { id: nil }).limit(8)
    users = users.presence || User.limit(8)

    render SharkDrawComponent.new(users: users, challenge: challenge)
  end

  # Shows the shark draw with 3 swimmers (quicker animation)
  # @label With 3 Swimmers (Quick)
  def three_swimmers
    challenge = Challenge.first || FactoryBot.create(:challenge)
    users = User.left_joins(:avatar_attachment).where(active_storage_attachments: { id: nil }).limit(3)
    users = users.presence || User.limit(3)

    render SharkDrawComponent.new(users: users, challenge: challenge)
  end

  # Shows the shark draw with 5 swimmers
  # @label With 5 Swimmers
  def five_swimmers
    challenge = Challenge.first || FactoryBot.create(:challenge)
    users = User.left_joins(:avatar_attachment).where(active_storage_attachments: { id: nil }).limit(5)
    users = users.presence || User.limit(5)

    render SharkDrawComponent.new(users: users, challenge: challenge)
  end

  # Shows the component with no users (empty state)
  # @label No Users (Empty State)
  def no_users
    challenge = Challenge.first || FactoryBot.create(:challenge)

    render SharkDrawComponent.new(users: [], challenge: challenge)
  end

  # Shows the shark draw with 30 swimmers (large group)
  # @label With 30 Swimmers (Large)
  def thirty_swimmers
    challenge = Challenge.first || FactoryBot.create(:challenge)
    users = User.limit(30)

    render SharkDrawComponent.new(users: users, challenge: challenge)
  end
end
