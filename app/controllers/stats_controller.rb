# frozen_string_literal: true

class StatsController < ApplicationController
  def index
  end

  def challenge
    @top_readers_data = TopReadersStatistics.call
  end

  def group
  end

  def personal
  end
end