# Statistics for all current group rosters, with a fixed number of aggregate queries.
# Keep the percentage rounding and date bounds used by GroupStatistics.
class ManageGroupStatistics
  attr_reader :participants
  delegate :today, :through_date, :scheduled_count, to: :participants

  def initialize(challenge, groups)
    @groups = groups
    @participants = ManageParticipantStatistics.new(challenge, groups.flat_map { |group| group.users.map(&:id) })
  end

  def rows
    @rows ||= @groups.map do |group|
      members = group.users.map { |user| participants.by_user_id.fetch(user.id) }
      count = members.size
      read = members.sum { |member| member[:completed_readings] }
      expected = scheduled_count * count
      {
        group: group,
        member_count: count,
        on_schedule_percentage: count.zero? ? 0 : members.sum { |member| member[:on_schedule_percentage] } / count,
        completion_percentage: expected.zero? ? 0 : (read.to_f / expected * 100).floor,
        completed_readings: read,
        missing_readings: expected - read,
        caught_up_members: members.count { |member| member[:caught_up] },
        active_members: members.count { |member| member[:active] },
        not_started_members: members.count { |member| member[:completed_readings].zero? },
        last_activity: members.filter_map { |member| member[:last_activity] }.max
      }
    end.sort_by { |row| [ -row[:on_schedule_percentage], -row[:completion_percentage], -row[:member_count], row[:group].name, row[:group].id ] }
  end
end
