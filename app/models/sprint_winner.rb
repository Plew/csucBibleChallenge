class SprintWinner < ApplicationRecord
  belongs_to :sprint
  belongs_to :group

  validates :completion_percentage, presence: true
  validates :on_schedule_percentage, presence: true
  validates :sprint_id, uniqueness: { scope: :group_id }
end
