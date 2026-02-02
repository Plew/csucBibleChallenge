# frozen_string_literal: true

class SharkDrawComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :users, :challenge

  def initialize(users:, challenge:)
    @users = users
    @challenge = challenge
  end
end
