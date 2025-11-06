class AddCompositeIndexToVerses < ActiveRecord::Migration[8.0]
  def change
    add_index :verses, [ :version, :book_number, :chapter_number, :verse_number ],
              unique: true,
              name: 'index_verses_on_version_book_chapter_verse'
  end
end
