class Manage::ChooserController < ApplicationController
  before_action :require_login

  def index
    @manageable_challenges = current_user.directly_managed_challenges
    if @manageable_challenges.count == 1
      redirect_to challenge_manage_dashboard_path(@manageable_challenges.first)
    end
  end
end
