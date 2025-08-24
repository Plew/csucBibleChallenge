# frozen_string_literal: true

class StatsPageComponent < ViewComponent::Base
  def initialize
  end

  private

  def stats_options
    [
      {
        title: "Challenge Stats",
        description: "View statistics across all reading challenges",
        path: stats_challenge_path,
        icon: "📊"
      },
      {
        title: "Group Stats", 
        description: "Compare performance between different groups",
        path: stats_group_path,
        icon: "👥"
      },
      {
        title: "Personal Stats",
        description: "Your individual reading progress and achievements", 
        path: stats_personal_path,
        icon: "📈"
      }
    ]
  end
end