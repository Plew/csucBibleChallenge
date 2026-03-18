# frozen_string_literal: true

class Statistics::PerfectRecordComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(perfect_record_data:)
    @perfect_record_data = perfect_record_data
  end

  private

  attr_reader :perfect_record_data

  def users
    perfect_record_data[:users]
  end

  def days_count
    perfect_record_data[:days_count]
  end

  def user_count
    users.length
  end
end
