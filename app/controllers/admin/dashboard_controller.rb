class Admin::DashboardController < Admin::BaseController
  def index
    @challenges_count = Challenge.count
    @users_count = User.count
    @feedbacks_count = Feedback.count
  end
end
