class Verse < ApplicationRecord
  # Verse messages are now associated with readings, not individual verses
  # This allows comments to be version-agnostic

  validates :version, presence: true
  validates :book_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 } # Assuming book numbers are 1-indexed
  validates :chapter_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :verse_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :verse_text, presence: true

  # For uniqueness, you might consider a composite index and validation if a verse is unique per version, book, chapter, and number.
  # validates :verse_number, uniqueness: { scope: [:version, :book_number, :chapter_number] }
  # This would also require a unique composite index in the database migration:
  # add_index :verses, [:version, :book_number, :chapter_number, :verse_number], unique: true, name: 'index_verses_on_version_book_chap_verse'
end
