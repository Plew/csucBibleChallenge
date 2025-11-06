class Admin::BaseController < ApplicationController
  before_action :ensure_admin!

  private

  def ensure_admin!
    unless logged_in?
      redirect_to new_user_session_path
      return
    end

    unless current_user.admin?
      redirect_to root_path, alert: "Access denied."
    end
  end
end
