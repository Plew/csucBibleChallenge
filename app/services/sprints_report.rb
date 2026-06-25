# Lists a challenge's sprints with their dates, status, and recorded winners.
# Returned by the sprints index endpoint. Winners come from the stored
# SprintWinner records; full ranked standings are computed live by
# SprintStandings (the per-sprint show endpoint).
class SprintsReport
  def initialize(challenge)
    @challenge = challenge
  end

  def as_json(*)
    {
      challenge: { id: @challenge.id, name: @challenge.name },
      sprints: sprints,
      generated_at: Time.current.iso8601
    }
  end

  private

  def sprints
    @challenge.sprints.ordered.includes(:sprint_winners).map do |sprint|
      {
        id: sprint.id,
        title: sprint.title,
        begin_date: sprint.begin_date,
        end_date: sprint.end_date,
        days: sprint.days_count,
        status: sprint.status,
        winners_calculated: sprint.sprint_winners.present?,
        winners: winners(sprint)
      }
    end
  end

  def winners(sprint)
    sprint.sprint_winners
          .sort_by { |w| w.group_name.to_s }
          .map do |winner|
            {
              group_id: winner.group_id,
              group_name: winner.display_group_name,
              completion_percentage: winner.completion_percentage,
              on_schedule_percentage: winner.on_schedule_percentage
            }
          end
  end
end
