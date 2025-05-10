class AddBookAndChapterToReadings < ActiveRecord::Migration[8.0]
  def change
    add_column :readings, :book_number, :integer
    add_column :readings, :chapter_number, :integer
  end
end
