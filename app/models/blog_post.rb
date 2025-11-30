class BlogPost < ApplicationRecord
  belongs_to :challenge
  belongs_to :user
  has_many :blog_comments, dependent: :destroy
  has_one_attached :image

  validates :title, presence: true
  validates :content, presence: true
  validates :visible, inclusion: { in: [ true, false ] }
  validate :acceptable_image

  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(created_at: :desc) }

  def author
    user
  end

  private

  def acceptable_image
    return unless image.attached?

    unless image.blob.byte_size <= 10.megabytes
      errors.add(:image, "must be less than 10MB")
    end

    acceptable_types = %w[image/jpeg image/jpg image/png image/gif image/webp]
    unless acceptable_types.include?(image.content_type)
      errors.add(:image, "must be a valid image format (JPEG, PNG, GIF, or WebP)")
    end
  end
end
