class BlogComment < ApplicationRecord
  belongs_to :blog_post
  belongs_to :user

  validates :content, presence: true

  scope :ordered, -> { order(created_at: :asc) }
end
