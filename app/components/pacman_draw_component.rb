# frozen_string_literal: true

class PacmanDrawComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :users, :challenge

  def initialize(users:, challenge:)
    @users = users
    @challenge = challenge
  end

  # Assign ghost colors to users (cycling through classic Pac-Man ghost colors)
  def ghost_color_for(index)
    colors = %w[red pink cyan orange]
    colors[index % colors.length]
  end
end
