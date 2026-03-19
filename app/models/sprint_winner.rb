class SprintWinner < ApplicationRecord
  belongs_to :sprint
  belongs_to :group, optional: true

  def display_group_name
    group&.name || group_name || I18n.t("stats.deleted_group")
  end

  validates :completion_percentage, presence: true
  validates :on_schedule_percentage, presence: true
  validates :sprint_id, uniqueness: { scope: :group_id }
end
