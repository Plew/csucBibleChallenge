class Admin::DashboardController < Admin::BaseController
  def index
    @challenges_count = Challenge.count
    @users_count = User.count
    @recent_challenges = Challenge.order(created_at: :desc).limit(5)
  end
end
