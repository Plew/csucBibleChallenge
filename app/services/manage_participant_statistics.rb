# Shared reporting window and batched individual statistics for admin reports.
class ManageParticipantStatistics
  attr_reader :challenge, :today, :through_date, :scheduled_count

  def initialize(challenge, user_ids)
    @challenge = challenge
    @user_ids = user_ids.uniq
    @today = Time.current.in_time_zone(challenge.timezone).to_date
    @through_date = [ challenge.stats_end_date || today, today ].min
    @scheduled_count = due_readings.count
  end

  def by_user_id
    @by_user_id ||= begin
      completions = UserReading.where(user_id: @user_ids, reading_id: due_readings.select(:id))
      completed = completions.group(:user_id).count
      last_activity = completions.group(:user_id).maximum(:completed_on)
      activity_dates = completions.where(completed_on: (today - 14)..today)
        .distinct.pluck(:user_id, :completed_on).group_by(&:first)
      on_target = OnScheduleStatistic.batch_percentages(@user_ids, challenge)

      @user_ids.index_with do |id|
        read = completed.fetch(id, 0)
        dates = activity_dates.fetch(id, []).map(&:last)
        {
          on_schedule_percentage: on_target.fetch(id, 0),
          completion_percentage: scheduled_count.zero? ? 0 : (read.to_f / scheduled_count * 100).floor,
          completed_readings: read,
          missing_readings: scheduled_count - read,
          caught_up: scheduled_count.positive? && read == scheduled_count,
          active: dates.any? { |date| date >= today - 6 },
          last_activity: last_activity[id],
          activity_days: ((today - 14)..today).map { |date| dates.include?(date) }
        }
      end
    end
  end

  private

  def due_readings
    @due_readings ||= begin
      scope = challenge.readings.where("scheduled_date <= ?", through_date)
      scope = scope.where("scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date
      scope
    end
  end
end
