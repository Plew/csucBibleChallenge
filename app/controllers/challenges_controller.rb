class ChallengesController < ApplicationController
  before_action :require_login, only: [:index]

  # GET /challenges
  def index
    if current_user
      @my_challenges = current_user.challenges.includes(:creator)
      @available_challenges = Challenge.includes(:creator).where.not(id: @my_challenges.pluck(:id))
    else
      @my_challenges = []
      @available_challenges = Challenge.includes(:creator).all
    end
  end

  # GET /challenges/:id
  def show
    @challenge = Challenge.find(params[:id])
  end

  # GET /challenges/:id/summary
  def summary
    @challenge = Challenge.find(params[:id])
  end
end 