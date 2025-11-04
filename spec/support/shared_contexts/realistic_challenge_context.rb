# frozen_string_literal: true

# Shared context that creates a realistic challenge scenario with:
# - A challenge with 21 readings (Gospel of John)
# - Multiple users with varied activity levels
# - Groups with messages
# - Varied reading completion progress
#
# Usage in request specs:
#   include_context 'realistic challenge'
#
#   it 'loads the stats page' do
#     get stats_path
#     expect(response).to have_http_status(:success)
#   end

RSpec.shared_context 'realistic challenge' do
  # Core challenge setup
  let!(:challenge) do
    create(:challenge,
      name: 'Test Gospel Reading',
      start_date: Date.current - 7.days,
      end_date: Date.current + 14.days,
      timezone: 'Eastern Time (US & Canada)'
    )
  end

  # Create 21 readings for Gospel of John
  let!(:readings) do
    (1..21).map do |chapter|
      create(:reading,
        challenge: challenge,
        book_number: 43, # John
        chapter_number: chapter,
        scheduled_date: challenge.start_date + (chapter - 1).days
      )
    end
  end

  # Create varied users with different activity levels
  let!(:primary_user) do
    create(:user,
      username: 'primary_tester',
      email: 'primary@example.com'
    )
  end

  let!(:active_user) do
    create(:user,
      username: 'active_reader',
      email: 'active@example.com'
    )
  end

  let!(:moderate_user) do
    create(:user,
      username: 'moderate_reader',
      email: 'moderate@example.com'
    )
  end

  let!(:casual_user) do
    create(:user,
      username: 'casual_reader',
      email: 'casual@example.com'
    )
  end

  let!(:inactive_user) do
    create(:user,
      username: 'inactive_reader',
      email: 'inactive@example.com'
    )
  end

  # Enroll all users in the challenge
  let!(:primary_enrollment) do
    create(:user_challenge_enrollment, user: primary_user, challenge: challenge)
  end

  let!(:active_enrollment) do
    create(:user_challenge_enrollment, user: active_user, challenge: challenge)
  end

  let!(:moderate_enrollment) do
    create(:user_challenge_enrollment, user: moderate_user, challenge: challenge)
  end

  let!(:casual_enrollment) do
    create(:user_challenge_enrollment, user: casual_user, challenge: challenge)
  end

  let!(:inactive_enrollment) do
    create(:user_challenge_enrollment, user: inactive_user, challenge: challenge)
  end

  # Create groups
  let!(:primary_group) do
    create(:group,
      challenge: challenge,
      creator: primary_user,
      name: 'Accountability Partners'
    )
  end

  let!(:secondary_group) do
    create(:group,
      challenge: challenge,
      creator: active_user,
      name: 'Morning Readers'
    )
  end

  # Group enrollments
  let!(:primary_group_enrollments) do
    [
      create(:user_group_enrollment, user: primary_user, group: primary_group),
      create(:user_group_enrollment, user: active_user, group: primary_group),
      create(:user_group_enrollment, user: moderate_user, group: primary_group)
    ]
  end

  let!(:secondary_group_enrollments) do
    [
      create(:user_group_enrollment, user: active_user, group: secondary_group),
      create(:user_group_enrollment, user: casual_user, group: secondary_group)
    ]
  end

  # Group messages
  let!(:group_messages) do
    [
      create(:group_message,
        group: primary_group,
        user: primary_user,
        content: 'Looking forward to reading together!'
      ),
      create(:group_message,
        group: primary_group,
        user: active_user,
        content: "Today's passage was really encouraging."
      ),
      create(:group_message,
        group: primary_group,
        user: moderate_user,
        content: 'Anyone have thoughts on chapter 3?'
      ),
      create(:group_message,
        group: secondary_group,
        user: active_user,
        content: "I'm loving the early morning reading time."
      ),
      create(:group_message,
        group: secondary_group,
        user: casual_user,
        content: 'Great group! Keep it up everyone.'
      )
    ]
  end

  # Completed readings - varied progress
  let!(:completed_readings) do
    past_readings = readings.select { |r| r.scheduled_date <= Date.current }

    completions = []

    # Primary user: 75% completion
    past_readings.sample((past_readings.count * 0.75).to_i).each do |reading|
      completions << create(:user_reading,
        user: primary_user,
        reading: reading,
        completed_on: reading.scheduled_date
      )
    end

    # Active user: 100% completion
    past_readings.each do |reading|
      completions << create(:user_reading,
        user: active_user,
        reading: reading,
        completed_on: reading.scheduled_date
      )
    end

    # Moderate user: 50% completion
    past_readings.sample((past_readings.count * 0.5).to_i).each do |reading|
      completions << create(:user_reading,
        user: moderate_user,
        reading: reading,
        completed_on: reading.scheduled_date
      )
    end

    # Casual user: 25% completion
    past_readings.sample((past_readings.count * 0.25).to_i).each do |reading|
      completions << create(:user_reading,
        user: casual_user,
        reading: reading,
        completed_on: reading.scheduled_date
      )
    end

    # Inactive user: 0% completion (no readings)

    completions
  end
end
