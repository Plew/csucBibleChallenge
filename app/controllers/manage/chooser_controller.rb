class Manage::ChooserController < ApplicationController
  before_action :require_login

  def index
    @manageable_challenges = current_user.directly_managed_challenges

    if (active_ch = current_active_challenge) && active_ch.manageable_by?(current_user)
      redirect_to challenge_manage_dashboard_path(active_ch)
      return
    end

    if @manageable_challenges.count == 1
      redirect_to challenge_manage_dashboard_path(@manageable_challenges.first)
      return
    end

    if @manageable_challenges.empty?
      redirect_to root_path, alert: t("manage.access_denied", default: "You do not have permission to manage any challenges.")
      return
    end
  end
end
