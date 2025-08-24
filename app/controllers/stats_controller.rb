# frozen_string_literal: true

class StatsController < ApplicationController
  def index
  end

  def challenge
    current_challenge = current_user.challenges.first
    @top_readers_data = TopReadersStatistics.call(challenge: current_challenge)
  end

  def group
    current_challenge = current_user.challenges.first
    @top_groups_data = TopGroupsStatistics.call(challenge: current_challenge)
  end

  def personal
  end
end