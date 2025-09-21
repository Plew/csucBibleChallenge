class AddInvitationTokenToChallenges < ActiveRecord::Migration[8.0]
  def change
    add_column :challenges, :invitation_token, :string
    add_index :challenges, :invitation_token, unique: true
  end
end
