require 'rails_helper'

RSpec.describe ManageGroupStatistics do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.utc(2026, 9, 24, 1)) { example.run } }

  let(:challenge) { create(:challenge, timezone: 'Eastern Time (US & Canada)', start_date: Date.new(2026, 9, 1), stats_start_date: Date.new(2026, 9, 20), end_date: Date.new(2026, 10, 1)) }
  let(:group) { create(:group, challenge: challenge) }
  let(:reader) { create(:user) }
  let(:idle) { create(:user) }
  let(:report) { described_class.new(challenge, challenge.groups.includes(:users)) }

  before do
    [reader, idle].each { |user| create(:user_group_enrollment, group: group, user: user) }
  end

  it 'matches existing percentages and includes missing, catch-up and recent participation counts' do
    first = create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 20))
    second = create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 21))
    create(:user_reading, user: reader, reading: first, completed_on: first.scheduled_date)
    create(:user_reading, user: reader, reading: second, completed_on: Date.new(2026, 9, 23))
    # Exclude readings before the configured window, tomorrow in the challenge's
    # timezone, and readings belonging to another challenge.
    [create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 19)),
     create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 24)),
     create(:reading)].each do |reading|
      create(:user_reading, user: idle, reading: reading, completed_on: Date.new(2026, 9, 23))
    end

    row = report.rows.first
    expect(report.today).to eq(Date.new(2026, 9, 23))
    expect(report.scheduled_count).to eq(2)
    expect(row).to include(member_count: 2, completion_percentage: 50, on_schedule_percentage: 25,
                           completed_readings: 2, missing_readings: 2, caught_up_members: 1,
                           active_members: 1, not_started_members: 1, last_activity: Date.new(2026, 9, 23))
    expect(row[:completion_percentage]).to eq(GroupStatistics.new(group).completion_percentage)
    expect(row[:on_schedule_percentage]).to eq(GroupStatistics.new(group).on_schedule_percentage)
  end

  it 'keeps the existing per-member rounding for on-target percentages' do
    3.times do |index|
      reading = create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 20) + index)
      create(:user_reading, user: reader, reading: reading, completed_on: reading.scheduled_date) if index.zero?
      create(:user_reading, user: idle, reading: reading, completed_on: reading.scheduled_date) if index < 2
    end
    expect(report.rows.first[:on_schedule_percentage]).to eq(49)
    expect(report.rows.first[:completion_percentage]).to eq(50)
  end

  it 'honors the statistics end date' do
    challenge.update!(stats_end_date: Date.new(2026, 9, 20))
    create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 21))
    expect(report.scheduled_count).to eq(0)
    expect(report.rows.first).to include(completion_percentage: 0, caught_up_members: 0)
  end

  it 'handles empty groups and a future reporting period' do
    challenge.update!(stats_start_date: Date.new(2026, 9, 25))
    empty = create(:group, challenge: challenge)
    row = report.rows.find { |data| data[:group] == empty }
    expect(row).to include(member_count: 0, completion_percentage: 0, on_schedule_percentage: 0,
                          missing_readings: 0, caught_up_members: 0, active_members: 0, last_activity: nil)
  end
  it 'does not add aggregate queries as the number of groups grows' do
    create(:reading, challenge: challenge, scheduled_date: Date.new(2026, 9, 20))
    count_queries = lambda do
      queries = []
      callback = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] if payload[:sql].match?(/\ASELECT/i) }
      ActiveRecord::Base.uncached do
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          described_class.new(challenge, challenge.groups.includes(:users)).rows
        end
      end
      queries.size
    end
    original_count = count_queries.call
    3.times do
      extra = create(:group, challenge: challenge)
      create(:user_group_enrollment, group: extra, user: create(:user))
    end
    expect(count_queries.call).to eq(original_count)
  end

end
