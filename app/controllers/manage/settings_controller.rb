class Manage::SettingsController < Manage::BaseController
  def edit
  end

  def update
    if @challenge.update(settings_params)
      redirect_to challenge_manage_dashboard_path(@challenge), notice: t("manage.settings.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:challenge).permit(:title, :name, :description, :start_date, :timezone, :hidden, :locked, :verse_comments_enabled, :message_of_the_day, :auto_remove_inactive_from_groups)
  end
end
