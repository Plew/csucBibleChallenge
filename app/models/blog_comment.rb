class BlogComment < ApplicationRecord
  belongs_to :blog_post
  belongs_to :user

  validates :content, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
end
