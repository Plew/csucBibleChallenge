# Builds the full per-group graph within a single challenge: the group's
# profile, its members (participants) with their progress, aggregate group
# stats, and how the group performed in each of the challenge's sprints.
# Scoped to the given challenge (the API key grants access to one challenge).
class GroupReport
  def initialize(challenge, group)
    @challenge = challenge
    @group = group
  end

  def as_json(*)
    {
      group: group_hash,
      challenge: { id: @challenge.id, name: @challenge.name },
      stats: stats_hash,
      members: members,
      sprints: sprints,
      generated_at: Time.current.iso8601
    }
  end

  private

  def reading_ids
    @reading_ids ||= @challenge.readings.pluck(:id)
  end

  def member_user_ids
    @member_user_ids ||= @group.user_group_enrollments.pluck(:user_id)
  end

  def group_hash
    {
      id: @group.id,
      name: @group.name,
      motto: @group.motto,
      country_code: @group.country_code,
      country: @group.country&.iso_short_name,
      closed_to_new_members: @group.closed_to_new_members,
      created_at: @group.created_at.iso8601,
      creator: { id: @group.creator_id, username: @group.creator&.username }
    }
  end

  def stats_hash
    gs = GroupStatistics.new(@group)
    {
      members: member_user_ids.size,
      completion_percentage: gs.completion_percentage,
      on_schedule_percentage: gs.on_schedule_percentage,
      longest_group_streak: gs.longest_group_streak,
      total_chapters_read: gs.total_chapters_read
    }
  end

  def members
    @members ||=
      @group.user_group_enrollments.includes(:user).order(:created_at).map do |enrollment|
        user = enrollment.user
        {
          user_id: user.id,
          username: user.username,
          role: challenge_roles[user.id],
          joined_group_at: enrollment.created_at.iso8601,
          readings_completed: completions_by_user[user.id] || 0,
          last_completed_on: last_completed_by_user[user.id]
        }
      end
  end

  def sprints
    @sprints ||=
      @challenge.sprints.ordered.map do |sprint|
        gs = GroupStatistics.new(@group, sprint.date_range)
        {
          sprint_id: sprint.id,
          title: sprint.title,
          begin_date: sprint.begin_date,
          end_date: sprint.end_date,
          status: sprint.status,
          completion_percentage: gs.completion_percentage,
          on_schedule_percentage: gs.on_schedule_percentage,
          won: won_sprint_ids.include?(sprint.id)
        }
      end
  end

  def challenge_roles
    @challenge_roles ||=
      @challenge.user_challenge_enrollments.where(user_id: member_user_ids).pluck(:user_id, :role).to_h
  end

  def completions_by_user
    @completions_by_user ||=
      UserReading.where(user_id: member_user_ids, reading_id: reading_ids).group(:user_id).count
  end

  def last_completed_by_user
    @last_completed_by_user ||=
      UserReading.where(user_id: member_user_ids, reading_id: reading_ids).group(:user_id).maximum(:completed_on)
  end

  def won_sprint_ids
    @won_sprint_ids ||=
      SprintWinner.where(sprint_id: @challenge.sprints.select(:id), group_id: @group.id).pluck(:sprint_id).to_set
  end
end
