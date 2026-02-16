namespace :fix_philippians do
  desc "Preview: show the invalid Philippians 5 reading and readings that would shift"
  task preview: :environment do
    challenge = Challenge.find(9)
    invalid = challenge.readings.find_by(book_number: 50, chapter_number: 5)

    if invalid.nil?
      puts "No Philippians chapter 5 found in challenge 9. Nothing to fix."
      next
    end

    puts "=== Invalid Reading ==="
    puts "  ID: #{invalid.id}, Book: #{invalid.book_number}, Chapter: #{invalid.chapter_number}, Date: #{invalid.scheduled_date}"

    completions = invalid.user_readings.count
    puts "  Completions: #{completions}"

    readings_to_shift = challenge.readings.where("scheduled_date > ?", invalid.scheduled_date).order(:scheduled_date)
    puts "\n=== Readings to shift back by 1 day: #{readings_to_shift.count} ==="

    affected_completions = UserReading.where(reading_id: readings_to_shift.select(:id)).count
    puts "  Completions on affected readings: #{affected_completions}"

    if affected_completions > 0
      puts "\n  WARNING: There are user completions on readings that would be shifted!"
    end

    puts "\n=== Date range change ==="
    last_reading = challenge.readings.order(:scheduled_date).last
    puts "  Current last reading: #{last_reading.scheduled_date}"
    puts "  New last reading:     #{last_reading.scheduled_date - 1.day}"
    puts "\n=== Challenge end_date ==="
    puts "  Current end_date: #{challenge.end_date}"
    puts "  New end_date:     #{last_reading.scheduled_date - 1.day}"
    puts "\nTotal readings: #{challenge.readings.count} -> #{challenge.readings.count - 1}"
  end

  desc "Fix: delete Philippians 5 and shift subsequent reading dates back by 1 day"
  task fix: :environment do
    challenge = Challenge.find(9)
    invalid = challenge.readings.find_by(book_number: 50, chapter_number: 5)

    if invalid.nil?
      puts "No Philippians chapter 5 found in challenge 9. Nothing to fix."
      next
    end

    affected_completions = UserReading.where(reading_id: challenge.readings.where("scheduled_date >= ?", invalid.scheduled_date).select(:id)).count
    if affected_completions > 0
      puts "ABORTING: There are #{affected_completions} user completions on affected readings. Not safe to proceed."
      next
    end

    ActiveRecord::Base.transaction do
      readings_to_shift = challenge.readings.where("scheduled_date > ?", invalid.scheduled_date)
      shift_count = readings_to_shift.count

      invalid.destroy!
      puts "Deleted Philippians chapter 5 (reading ID: #{invalid.id})"

      readings_to_shift.find_each do |reading|
        reading.update!(scheduled_date: reading.scheduled_date - 1.day)
      end
      puts "Shifted #{shift_count} readings back by 1 day"

      new_end_date = challenge.readings.order(:scheduled_date).last.scheduled_date
      challenge.update!(end_date: new_end_date)
      puts "Updated challenge end_date to #{new_end_date}"

      puts "\nChallenge 9 now has #{challenge.readings.count} readings"
      puts "Duration: #{(challenge.end_date - challenge.start_date).to_i + 1} days"
    end
  end
end
