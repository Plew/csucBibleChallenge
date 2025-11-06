class SevenDayLeaderboardComponentPreview < ViewComponent::Preview
  def default
    render SevenDayLeaderboardComponent.new(
      leaderboard_data: sample_leaderboard_data
    )
  end

  def empty_state
    render SevenDayLeaderboardComponent.new(
      leaderboard_data: []
    )
  end

  def single_reader
    render SevenDayLeaderboardComponent.new(
      leaderboard_data: [ sample_leaderboard_data.first ]
    )
  end

  private

  def sample_leaderboard_data
    [
      {
        name: "Jim Thompson",
        completion_percentage: 100,
        on_schedule_percentage: 100
      },
      {
        name: "Sally Martinez",
        completion_percentage: 100,
        on_schedule_percentage: 86
      },
      {
        name: "Shirley Johnson",
        completion_percentage: 100,
        on_schedule_percentage: 71
      },
      {
        name: "Mike Wilson",
        completion_percentage: 86,
        on_schedule_percentage: 86
      },
      {
        name: "Linda Davis",
        completion_percentage: 71,
        on_schedule_percentage: 57
      }
    ]
  end
end
