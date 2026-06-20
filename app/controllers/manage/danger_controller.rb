class Manage::DangerController < Manage::BaseController
  CONFIRMATION_TEXT = "i want this".freeze

  before_action :require_owner_or_admin!

  def show
  end

  def destroy
    if params[:confirmation_text] != CONFIRMATION_TEXT
      redirect_to challenge_manage_danger_path(@challenge),
                  alert: t("manage.danger.confirm", title: @challenge.title)
      return
    end

    @challenge.destroy
    redirect_to root_path, notice: t("manage.danger.deleted")
  end

  private

  def require_owner_or_admin!
    unless @challenge.owner_or_site_admin?(current_user)
      redirect_to challenge_manage_dashboard_path(@challenge), alert: t("manage.access_denied")
    end
  end
end
