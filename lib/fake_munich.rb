# frozen_string_literal: true

# Usage: require and call FakeMunich.generate!
# This script deletes and recreates the Munich Fall Reading Challenge, groups, users, readings, and enrollments.
# It also simulates user reading completions for experimentation.

class FakeMunich
  CHALLENGE_NAME = 'Munich Fall Reading Challenge'.freeze
  GROUP_NAMES = %w[Sauerkraut Bratwurst Pretzel Schnitzel].freeze
  GERMAN_NAMES = [
    ['Lukas', 'Müller'],
    ['Anna', 'Schmidt'],
    ['Max', 'Schneider'],
    ['Sophie', 'Fischer'],
    ['Leon', 'Weber'],
    ['Mia', 'Meyer'],
    ['Ben', 'Wagner'],
    ['Emma', 'Becker'],
    ['Paul', 'Hoffmann'],
    ['Laura', 'Schäfer']
  ].freeze
  BOOK_NUMBER = 43 # John
  CHAPTER_COUNT = 21
  USER_PASSWORD = 'password123'.freeze

  def self.generate!
    new.generate!
  end

  def generate!
    puts 'Resetting fake Munich challenge data...'
    delete_existing_data
    puts 'Creating challenge, groups, readings, users, and enrollments...'
    create_challenge_and_groups
    create_readings
    create_users_and_enrollments
    simulate_user_readings
    puts 'Fake Munich challenge data generated.'
  end

  private

  def delete_existing_data
    challenge = Challenge.find_by(name: CHALLENGE_NAME)
    return unless challenge

    # Delete user_readings for users in this challenge
    user_ids = challenge.users.pluck(:id)
    UserReading.where(user_id: user_ids).delete_all
    # Delete enrollments
    UserChallengeEnrollment.where(challenge_id: challenge.id).delete_all
    # Delete readings
    challenge.readings.delete_all
    # Delete groups
    challenge.groups.delete_all
    # Delete the challenge
    challenge.destroy
    # Delete fake users (by email domain)
    User.where(email: fake_user_emails).destroy_all
  end

  def create_challenge_and_groups
    @challenge = Challenge.create!(
      name: CHALLENGE_NAME,
      start_date: Date.today - 7,
      end_date: Date.today - 7 + 3.months,
      timezone: 'Berlin'
    )
    GROUP_NAMES.each { |name| @challenge.groups.create!(name: name) }
    @groups = @challenge.groups.order(:name).to_a
  end

  def create_readings
    (1..CHAPTER_COUNT).each do |chapter_num|
      scheduled_reading_date = @challenge.start_date + (chapter_num - 1).days
      @challenge.readings.create!(
        book_number: BOOK_NUMBER,
        chapter_number: chapter_num,
        title: "John Chapter #{chapter_num}",
        scheduled_date: scheduled_reading_date
      )
    end
    @readings = @challenge.readings.order(:scheduled_date).to_a
  end

  def create_users_and_enrollments
    @users = GERMAN_NAMES.each_with_index.map do |(first, last), idx|
      ascii_first = I18n.transliterate(first.downcase)
      ascii_last = I18n.transliterate(last.downcase)
      email = "#{ascii_first}.#{ascii_last}@example.com"
      user = User.create!(
        username: "#{ascii_first}#{ascii_last}",
        email: email,
        password: USER_PASSWORD
      )
      group = @groups[idx % @groups.size]
      UserChallengeEnrollment.create!(user: user, challenge: @challenge, group: group)
      user
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
      "#{ascii_first}.#{ascii_last}@example.com"
    end
  end
end 