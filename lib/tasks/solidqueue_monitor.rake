namespace :solidqueue do
  desc "Monitor SolidQueue job execution and status"
  task monitor: :environment do
    puts "\n=== SolidQueue Process Status ==="
    processes = SolidQueue::Process.all
    if processes.any?
      processes.each do |proc|
        puts "#{proc.kind.ljust(15)} - Last heartbeat: #{proc.last_heartbeat_at}"
      end
    else
      puts "No SolidQueue processes running!"
    end

    puts "\n=== Recent Job Executions (Last 24 hours) ==="
    jobs = SolidQueue::Job
      .where("created_at > ?", 24.hours.ago)
      .where.not(class_name: "SolidQueue::RecurringJob")
      .order(created_at: :desc)
      .limit(50)

    if jobs.any?
      jobs.group_by(&:class_name).each do |class_name, job_list|
        puts "\n#{class_name} (#{job_list.count} executions):"
        job_list.first(5).each do |job|
          status = job.finished_at ? "✓ Finished" : "⧗ Pending"
          duration = job.finished_at && job.started_at ? " (#{((job.finished_at - job.started_at) * 1000).round}ms)" : ""
          puts "  #{status} - #{job.created_at}#{duration}"
        end
        puts "  ... #{job_list.count - 5} more" if job_list.count > 5
      end
    else
      puts "No jobs found in last 24 hours"
    end

    puts "\n=== Recurring Task Executions (Last 24 hours) ==="
    executions = SolidQueue::RecurringExecution
      .where("created_at > ?", 24.hours.ago)
      .order(created_at: :desc)

    if executions.any?
      executions.group_by(&:task_key).each do |task_key, exec_list|
        puts "\n#{task_key} (#{exec_list.count} times):"
        exec_list.first(5).each do |exec|
          puts "  ✓ #{exec.run_at}"
        end
        puts "  ... #{exec_list.count - 5} more" if exec_list.count > 5
      end
    else
      puts "No recurring executions found"
    end

    puts "\n=== Failed Jobs (Last 7 days) ==="
    failed = SolidQueue::FailedExecution
      .where("created_at > ?", 7.days.ago)
      .order(created_at: :desc)
      .limit(10)

    if failed.any?
      failed.each do |fail|
        puts "\n❌ #{fail.job_class} - #{fail.created_at}"
        puts "   Error: #{fail.error.class}: #{fail.error.message}"
      end
    else
      puts "No failed jobs in last 7 days ✓"
    end
  end

  desc "Show details for a specific job type"
  task :job_details, [ :job_class ] => :environment do |t, args|
    job_class = args[:job_class] || "SendDailyReadingEmailsJob"

    puts "\n=== Details for #{job_class} ==="
    jobs = SolidQueue::Job
      .where(class_name: job_class)
      .order(created_at: :desc)
      .limit(20)

    if jobs.any?
      jobs.each do |job|
        status = if job.finished_at
          "✓ Finished"
        elsif job.started_at
          "⧗ Running"
        else
          "○ Pending"
        end

        duration = job.finished_at && job.started_at ?
          " (#{((job.finished_at - job.started_at) * 1000).round}ms)" : ""

        puts "#{status} - Created: #{job.created_at}#{duration}"
      end
    else
      puts "No jobs found for #{job_class}"
      puts "\nNote: Finished jobs are cleaned up periodically."
      puts "If you don't see recent executions, they may have been cleaned."
    end
  end

  desc "Check why emails weren't sent for a specific challenge"
  task :debug_email_sending, [ :challenge_name ] => :environment do |t, args|
    challenge_name = args[:challenge_name] || "Sample Email Challenge"

    puts "\n=== Debugging Email Sending for '#{challenge_name}' ==="
    challenge = Challenge.find_by(name: challenge_name)

    unless challenge
      puts "Challenge not found!"
      exit 1
    end

    server_time = Time.current
    challenge_time = server_time.in_time_zone(challenge.timezone)

    puts "\nTimezone Information:"
    puts "  Server time: #{server_time} (#{server_time.zone})"
    puts "  Challenge timezone: #{challenge.timezone}"
    puts "  Challenge time: #{challenge_time}"
    puts "  Challenge hour: #{challenge_time.hour}"
    puts "  Will send emails? #{challenge_time.hour == 6 ? "YES ✓" : "NO (needs to be hour 6)"}"

    puts "\nChallenge Status:"
    puts "  Active? #{challenge.active? ? "YES ✓" : "NO"}"
    puts "  Total enrolled users: #{challenge.users.count}"
    puts "  Users with daily_email enabled: #{challenge.users.wants_daily_email.count}"

    today = challenge_time.to_date
    reading = challenge.readings.find_by(scheduled_date: today)

    puts "\nToday's Reading (#{today}):"
    if reading
      puts "  ✓ Reading found: Book #{reading.book_number}, Chapter #{reading.chapter_number}"
      puts "  Completed by: #{reading.completed_by_users.count} users"
    else
      puts "  ✗ No reading scheduled for today"
    end

    puts "\nRecent EmailLoginTokens sent:"
    recent_tokens = EmailLoginToken
      .where(challenge: challenge)
      .where("sent_at > ?", 48.hours.ago)
      .order(sent_at: :desc)
      .limit(10)

    if recent_tokens.any?
      recent_tokens.each do |token|
        puts "  #{token.sent_at} - #{token.user.email}"
      end
    else
      puts "  No tokens sent in last 48 hours"
    end

    puts "\nNext email sending opportunity:"
    next_hour = (challenge_time + 1.hour).change(min: 0)
    hours_until_6am = ((6 - next_hour.hour) % 24)
    next_6am = next_hour + hours_until_6am.hours
    next_6am_utc = next_6am.utc
    puts "  Next 6am #{challenge.timezone}: #{next_6am}"
    puts "  That's #{next_6am_utc} UTC"
    puts "  Job will check at: #{next_6am_utc.change(min: 0)} UTC"
  end
end
