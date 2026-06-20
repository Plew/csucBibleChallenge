class Manage::BaseController < ApplicationController
  layout "manage"

  helper Admin::UsersHelper

  before_action :require_login
  before_action :set_challenge
  before_action :ensure_challenge_owner!

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def ensure_challenge_owner!
    unless @challenge.manageable_by?(current_user)
      redirect_to root_path, alert: t("manage.access_denied")
    end
  end
end
