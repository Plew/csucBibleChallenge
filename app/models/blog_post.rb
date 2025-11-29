class BlogPost < ApplicationRecord
  belongs_to :challenge
  belongs_to :user
  has_many :blog_comments, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true
  validates :visible, inclusion: { in: [ true, false ] }

  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(created_at: :desc) }

  def author
    user
  end
end
