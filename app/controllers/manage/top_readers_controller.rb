class Manage::TopReadersController < Manage::BaseController
  def index
    @readers = TopReadersStatistics.call(challenge: @challenge, min_completion_percentage: 0)
  end
end
