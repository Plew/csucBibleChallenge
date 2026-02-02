class Admin::SevenDayWinnerController < Admin::BaseController
  def draw
    # Get selected user IDs from params (passed from lobby start action)
    @selected_user_ids = params[:user_ids] || []
    @users = User.where(id: @selected_user_ids)
    @challenge = Challenge.find(params[:challenge_id])
    @animation_type = params[:animation_type] || "pile"
  end
end
