class Manage::SevenDayWinnerController < Manage::BaseController
  def draw
    @selected_user_ids = params[:user_ids] || []
    @users = User.where(id: @selected_user_ids)
    @animation_type = params[:animation_type] || "pile"
  end
end
