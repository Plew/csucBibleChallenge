# frozen_string_literal: true

# Usage: require and call FakeMunich.generate!
# This script deletes and recreates the Munich Fall Reading Challenge, groups, users, readings, and enrollments.
# It also simulates user reading completions for experimentation.

class FakeMunich
  CHALLENGE_NAME = "Munich Fall Reading Challenge".freeze
  UNIQUE_SUFFIX = Time.current.to_i.to_s[-6..-1] # Last 6 digits of timestamp
  GROUP_NAMES = %w[Sauerkraut Bratwurst Pretzel Schnitzel].freeze
  GERMAN_NAMES = [
    [ "Lukas", "Müller" ],
    [ "Anna", "Schmidt" ],
    [ "Max", "Schneider" ],
    [ "Sophie", "Fischer" ],
    [ "Leon", "Weber" ],
    [ "Mia", "Meyer" ],
    [ "Ben", "Wagner" ],
    [ "Emma", "Becker" ],
    [ "Paul", "Hoffmann" ],
    [ "Laura", "Schäfer" ],
    [ "Tim", "Keller" ],
    [ "Johanna", "Krüger" ],
    [ "Felix", "Baumann" ],
    [ "Clara", "Wolf" ],
    [ "Julian", "Koch" ],
    [ "Nina", "Voigt" ],
    [ "Moritz", "Hartmann" ],
    [ "Lena", "Zimmermann" ],
    [ "Fabian", "Brandt" ],
    [ "Sarah", "Krause" ]
  ].freeze
  BOOK_NUMBER = 43 # John
  CHAPTER_COUNT = 21
  USER_PASSWORD = "password123".freeze

  def self.generate!
    new.generate!
  end

  def generate!
    puts "Resetting fake Munich challenge data..."
    delete_existing_data
    puts "Creating challenge, groups, readings, users, and enrollments..."
    create_challenge_and_groups_and_users
    create_readings
    create_enrollments_and_group_memberships
    simulate_user_readings
    puts "Fake Munich challenge data generated."
  end

  private

  def delete_existing_data
    challenge = Challenge.find_by(name: CHALLENGE_NAME)
    return unless challenge

    # Wrap in transaction and temporarily disable foreign key checks for SQLite
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")

    begin
      ActiveRecord::Base.transaction do
        # 1. Delete user_readings first (they reference readings and users)
        reading_ids = challenge.readings.pluck(:id)
        UserReading.where(reading_id: reading_ids).delete_all

        # 2. Delete user group enrollments (they reference groups and users)
        group_ids = challenge.groups.pluck(:id)
        UserGroupEnrollment.where(group_id: group_ids).delete_all

        # 3. Delete user challenge enrollments (they reference challenge and users)
        UserChallengeEnrollment.where(challenge_id: challenge.id).delete_all

        # 4. Delete readings (they reference challenge)
        challenge.readings.delete_all

        # 5. Delete groups (they reference challenge and creator)
        challenge.groups.delete_all

        # 6. Delete the challenge
        challenge.delete

        # 7. Delete fake users last (they were referenced by everything above)
        User.where(email: fake_user_emails).delete_all
      end
    ensure
      # Re-enable foreign key checks
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
    end
  end

  # Create users first, then assign each group a unique creator from the users
  def create_challenge_and_groups_and_users
    # Create the first user to be the challenge creator
    first_name, last_name = GERMAN_NAMES.first
    ascii_first = I18n.transliterate(first_name.downcase)
    ascii_last = I18n.transliterate(last_name.downcase)
    email = "#{ascii_first}.#{ascii_last}.#{UNIQUE_SUFFIX}@example.com"
    challenge_creator = User.create!(
      username: "#{ascii_first}#{ascii_last}#{UNIQUE_SUFFIX}",
      email: email,
      password: USER_PASSWORD
    )

    @challenge = Challenge.create!(
      name: CHALLENGE_NAME,
      start_date: Date.today - 7,
      end_date: Date.today - 7 + 3.months,
      timezone: "Berlin",
      creator: challenge_creator
    )
    # Create remaining users and attach avatars (skip first user who is already the challenge creator)
    @users = [ challenge_creator ] + GERMAN_NAMES[1..-1].each_with_index.map do |(first, last), idx|
      ascii_first = I18n.transliterate(first.downcase)
      ascii_last = I18n.transliterate(last.downcase)
      email = "#{ascii_first}.#{ascii_last}.#{UNIQUE_SUFFIX}@example.com"
      user = User.create!(
        username: "#{ascii_first}#{ascii_last}#{UNIQUE_SUFFIX}",
        email: email,
        password: USER_PASSWORD
      )
      avatar_path = Rails.root.join("db", "fixtures", "avatars", "#{idx + 2}.jpg")
      if File.exist?(avatar_path)
        user.avatar.attach(
          io: File.open(avatar_path),
          filename: "#{idx + 2}.jpg",
          content_type: "image/jpeg"
        )
      end
      user
    end

    # Add avatar to challenge creator
    avatar_path = Rails.root.join("db", "fixtures", "avatars", "1.jpg")
    if File.exist?(avatar_path)
      challenge_creator.avatar.attach(
        io: File.open(avatar_path),
        filename: "1.jpg",
        content_type: "image/jpeg"
      )
    end
    # Assign each group a unique creator from the users
    @groups = GROUP_NAMES.each_with_index.map do |name, idx|
      @challenge.groups.create!(name: name, creator: @users[idx])
    end
  end

  def create_readings
    (1..CHAPTER_COUNT).each do |chapter_num|
      scheduled_reading_date = @challenge.start_date + (chapter_num - 1).days
      @challenge.readings.create!(
        book_number: BOOK_NUMBER,
        chapter_number: chapter_num,
        scheduled_date: scheduled_reading_date
      )
    end
    @readings = @challenge.readings.order(:scheduled_date).to_a
  end

  # Only assign each user to one group, and never assign a creator to another group
  def create_enrollments_and_group_memberships
    # The first N users are creators, each for one group
    # The rest are distributed round-robin to groups, skipping creators
    creator_users = @groups.map(&:creator)
    member_users = @users - creator_users
    group_count = @groups.size
    # Assign creators to their own group
    creator_users.each_with_index do |user, idx|
      UserChallengeEnrollment.create!(user: user, challenge: @challenge)
      UserGroupEnrollment.create!(user: user, group: @groups[idx])
    end
    # Assign remaining users to groups (round-robin, skipping creators)
    member_users.each_with_index do |user, idx|
      group = @groups[(idx) % group_count]
      UserChallengeEnrollment.create!(user: user, challenge: @challenge)
      UserGroupEnrollment.create!(user: user, group: group)
    end
  end

  def simulate_user_readings
    @users.each do |user|
      readings_to_complete = @readings.sample((@readings.size * 0.75).round)
      readings_to_complete.each do |reading|
        completed_on = reading.scheduled_date + rand(0..6) # Random day in the past 7 days
        completed_on = Date.today - rand(0..6) if completed_on > Date.today
        UserReading.create!(user: user, reading: reading, completed_on: completed_on)
      end
    end
  end

  def fake_user_emails
    GERMAN_NAMES.map do |first, last|
      ascii_first = I18n.transliterate(first.downcase)
      ascii_last = I18n.transliterate(last.downcase)
      "#{ascii_first}.#{ascii_last}.#{UNIQUE_SUFFIX}@example.com"
    end
  end
end
