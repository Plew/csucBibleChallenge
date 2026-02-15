class Manage::DashboardController < Manage::BaseController
  def index
    @user_count = @challenge.users.count
    @reading_count = @challenge.readings.count
    @group_count = @challenge.groups.count
    @sprint_count = @challenge.sprints.count
    @blog_post_count = @challenge.blog_posts.count
  end
end
