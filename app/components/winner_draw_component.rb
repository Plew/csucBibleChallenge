class WinnerDrawComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :users, :challenge

  def initialize(users:, challenge:)
    @users = users
    @challenge = challenge
  end
end
