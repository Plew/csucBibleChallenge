class ChangePasswordResetTokenName < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :password_reset_token, :reset_digest
  end
end
