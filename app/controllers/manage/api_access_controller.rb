class Manage::ApiAccessController < Manage::BaseController
  def show
  end

  def regenerate
    @challenge.regenerate_api_key!
    redirect_to challenge_manage_api_access_path(@challenge), notice: t("manage.api_access.regenerated")
  end
end
