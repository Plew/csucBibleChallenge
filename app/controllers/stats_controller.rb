# frozen_string_literal: true

class StatsController < ApplicationController
  def index
    @top_readers_data = TopReadersStatistics.call
  end
end