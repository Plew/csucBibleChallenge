class Feedback < ApplicationRecord
  belongs_to :user, optional: true
  has_one_attached :screenshot do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
    attachable.variant :medium, resize_to_limit: [400, 400]
  end

  enum :category, {
    bug: 0,
    suggestion: 1,
    other: 2
  }

  validates :category, presence: true
  validates :subject, presence: true, length: { maximum: 255 }
  validates :message, presence: true, length: { maximum: 2000 }

  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :recent, -> { order(created_at: :desc) }

  def anonymous?
    user.nil?
  end

  def author_name
    anonymous? ? "Anonymous" : user.username
  end

  def category_display
    category.humanize
  end
end