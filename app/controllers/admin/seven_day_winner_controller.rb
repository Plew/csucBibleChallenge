class Admin::SevenDayWinnerController < Admin::BaseController
  def index
    @challenges = Challenge.all.order(created_at: :desc)
  end

  def participants
    @challenge = Challenge.find(params[:challenge_id])

    # Get 7-day statistics for all participants
    all_stats = SevenDayWindowStatistics.call(challenge: @challenge)

    # Filter for users with 100% completion
    @perfect_participants = all_stats.select { |data| data[:completion_percentage] == 100 }

    # Get full user objects with stats
    @participants_data = @perfect_participants.map do |data|
      user = User.find_by(name: data[:name])
      {
        user: user,
        completion_percentage: data[:completion_percentage],
        on_schedule_percentage: data[:on_schedule_percentage]
      }
    end.compact
  end

  def draw
    # Get selected user IDs from params
    @selected_user_ids = params[:user_ids] || []
    @users = User.where(id: @selected_user_ids)
    @challenge = Challenge.find(params[:challenge_id])
  end
end
