class SetHideCopyrightOnChallenge9 < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE challenges SET hide_copyright = 1 WHERE id = 9"
  end

  def down
    execute "UPDATE challenges SET hide_copyright = 0 WHERE id = 9"
  end
end
