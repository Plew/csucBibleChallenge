class ChallengesController < ApplicationController
  before_action :require_login, only: [:index]

  # GET /challenges
  def index
    # In a real app, you would fetch the user's challenges and available challenges.
    # For now, using placeholder data based on the PRD.

    # @current_user_challenges = current_user.challenges if current_user
    # @available_challenges = Challenge.publicly_available.where.not(id: @current_user_challenges.pluck(:id) if @current_user_challenges)

    # Placeholder data for demonstration
    @my_challenges = [
      # OpenStruct.new(name: "Ongoing Genesis Study", dates: "Jan 1 - Dec 31", progress: "50%", group_name: "Morning Readers", id: 1),
      # OpenStruct.new(name: "Psalms in 30 Days", dates: "Oct 1 - Oct 30", progress: "10%", id: 2)
    ]
    @available_challenges = [
      # OpenStruct.new(name: "New Testament Overview", dates: "Nov 1 - Jan 30", description: "Read through the entire New Testament.", id: 3),
      # OpenStruct.new(name: "Proverbs Wisdom Challenge", dates: "Oct 15 - Nov 15", description: "A chapter a day from Proverbs.", creator: "Admin", id: 4)
    ]

    # Simulate cases for different UI states:
    # @my_challenges = [] # No challenges joined
    # @available_challenges = [] # No challenges available
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