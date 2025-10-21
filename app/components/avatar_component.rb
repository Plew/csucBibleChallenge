# frozen_string_literal: true

class AvatarComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(user:, size: :medium, html_options: {})
    @user = user
    @size = size
    @html_options = html_options
  end

  private

  attr_reader :user, :size, :html_options
end
