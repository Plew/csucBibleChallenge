class AddVerseCommentsEnabledToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :verse_comments_enabled, :boolean, default: true, null: false
  end
end
