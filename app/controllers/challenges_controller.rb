class ChallengesController < ApplicationController
  before_action :require_login, only: [:index]

  # GET /challenges
  def index
    if current_user
      @my_challenges = current_user.challenges.includes(:creator)
      @available_challenges = Challenge.includes(:creator).where.not(id: @my_challenges.pluck(:id)).where(hidden: false)
    else
      @my_challenges = []
      @available_challenges = Challenge.includes(:creator).where(hidden: false)
    end
  end

  # GET /challenges/:id
  def show
    @challenge = Challenge.find(params[:id])
    @user_count = @challenge.users.count
    @most_recent_user = @challenge.user_challenge_enrollments.includes(:user).order(created_at: :desc).first&.user
    @most_recent_join_time = @challenge.user_challenge_enrollments.order(created_at: :desc).first&.created_at
    @challenge_readings = @challenge.readings.order(:scheduled_date)
    @books_and_chapters = @challenge_readings.group_by(&:book_number).transform_values { |readings| readings.map(&:chapter_number) }
  end

  # GET /challenges/:id/summary
  def summary
    @challenge = Challenge.find(params[:id])
  end
end 