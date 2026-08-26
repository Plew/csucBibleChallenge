# frozen_string_literal: true

# Service class to recalculate and update scheduled dates for all readings in a challenge
# based on start_date, chapters_per_day, skip_days_of_week, and skip_dates.
class RescheduleChallengeReadings
  def self.call(challenge)
    readings = challenge.readings.order(:book_number, :chapter_number).to_a
    return if readings.empty? || challenge.start_date.blank?

    chapters_per_day = (challenge.chapters_per_day.presence || 1).to_i
    chapters_per_day = 1 if chapters_per_day < 1

    skip_days = challenge.skip_days_of_week_list
    skip_dates = challenge.skip_dates_list

    current_date = challenge.start_date.to_date
    last_scheduled_date = current_date

    Challenge.transaction do
      until readings.empty?
        if skip_days.include?(current_date.wday) || skip_dates.include?(current_date)
          current_date += 1.day
          next
        end

        batch = readings.shift(chapters_per_day)
        batch.each do |reading|
          reading.update!(scheduled_date: current_date)
        end
        last_scheduled_date = current_date
        current_date += 1.day unless readings.empty?
      end

      challenge.update!(end_date: last_scheduled_date)
    end

    true
  rescue StandardError => e
    Rails.logger.error("Failed to reschedule challenge readings: #{e.message}")
    false
  end
end
