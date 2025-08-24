# frozen_string_literal: true

class StatsPageComponent < ViewComponent::Base
  def initialize
  end

  private

  def stats_options
    [
      {
        title: "Challenge Stats",
        path: stats_challenge_path
      },
      {
        title: "Group Stats",
        path: stats_group_path
      },
      {
        title: "Personal Stats",
        path: stats_personal_path
      }
    ]
  end
end