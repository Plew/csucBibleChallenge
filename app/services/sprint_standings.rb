# Computes the live ranked standings for a single sprint: every group (with at
# least one member) ranked by reading completion, then on-schedule percentage,
# over the sprint's date range. Uses the same metrics and tie-breaking as
# Sprint#calculate_winners!, so rank 1 matches the recorded sprint winners.
# Standings are recomputed at request time, so an in-progress sprint reflects
# current progress.
class SprintStandings
  def initialize(sprint)
    @sprint = sprint
  end

  def as_json(*)
    {
      challenge: { id: @sprint.challenge_id, name: @sprint.challenge.name },
      sprint: sprint_hash,
      standings: standings,
      generated_at: Time.current.iso8601
    }
  end

  private

  def sprint_hash
    {
      id: @sprint.id,
      title: @sprint.title,
      begin_date: @sprint.begin_date,
      end_date: @sprint.end_date,
      days: @sprint.days_count,
      status: @sprint.status
    }
  end

  def standings
    rows = ranked_groups.map do |row|
      {
        rank: row[:rank],
        group_id: row[:group].id,
        group_name: row[:group].name,
        members: row[:group].user_group_enrollments.size,
        completion_percentage: row[:completion_percentage],
        on_schedule_percentage: row[:on_schedule_percentage]
      }
    end
    rows
  end

  def ranked_groups
    groups = @sprint.challenge.groups.joins(:user_group_enrollments).distinct.includes(:user_group_enrollments)

    rows = groups.map do |group|
      gs = GroupStatistics.new(group, @sprint.date_range)
      { group: group, completion_percentage: gs.completion_percentage, on_schedule_percentage: gs.on_schedule_percentage }
    end

    rows.sort_by! { |r| [ -r[:completion_percentage], -r[:on_schedule_percentage] ] }
    assign_ranks(rows)
  end

  # Standard competition ranking (1, 2, 2, 4): groups tied on both metrics
  # share the higher rank, and the next rank skips accordingly.
  def assign_ranks(rows)
    previous_key = nil
    previous_rank = 0

    rows.each_with_index.map do |row, index|
      key = [ row[:completion_percentage], row[:on_schedule_percentage] ]
      rank = key == previous_key ? previous_rank : index + 1
      previous_key = key
      previous_rank = rank
      row.merge(rank: rank)
    end
  end
end
