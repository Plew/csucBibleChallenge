# frozen_string_literal: true

class OverlaidAvatarsComponent < ViewComponent::Base
  include ApplicationHelper
  
  def initialize(users:, max_avatars: 5, size: :tiny)
    @users = users
    @max_avatars = max_avatars
    @size = size
  end

  private

  attr_reader :users, :max_avatars, :size

  def shown_users
    @shown_users ||= users.to_a.shuffle.first(max_avatars)
  end

  def extra_count
    @extra_count ||= [users.size - shown_users.size, 0].max
  end

  def has_extra_users?
    extra_count > 0
  end

  def avatar_container_width
    avatar_width = 32
    overlap = 24
    
    if max_avatars == 1
      avatar_width
    else
      avatar_width + (max_avatars - 1) * overlap
    end
  end
end