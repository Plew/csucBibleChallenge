class ChallengesController < ApplicationController

  # GET /challenges
  def index
    # Show simple list of active and upcoming challenges
    @challenges = Challenge.where('end_date >= ? AND hidden = ?', Date.current, false)
  end

  # GET /challenges/:id
  def show
    @challenge = Challenge.find(params[:id])
    @user_count = @challenge.users.count
    @most_recent_user = @challenge.user_challenge_enrollments.includes(:user).order(created_at: :desc).first&.user
    @most_recent_join_time = @challenge.user_challenge_enrollments.order(created_at: :desc).first&.created_at
    @challenge_readings = @challenge.readings.order(:scheduled_date)
    @books_and_chapters = @challenge_readings.group_by(&:book_number).transform_values { |readings| readings.map(&:chapter_number) }
    @user_enrollment = current_user&.user_challenge_enrollments&.find_by(challenge: @challenge)
  end

  # GET /challenges/:id/summary
  def summary
    @challenge = Challenge.find(params[:id])
  end
end 