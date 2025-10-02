class EnsureTokensOnGroupsAndChallenges < ActiveRecord::Migration[8.0]
  def up
    # Generate tokens for any groups that don't have one
    Group.where(token: nil).find_each do |group|
      loop do
        token = SecureRandom.alphanumeric(6)
        unless Group.exists?(token: token)
          group.update_column(:token, token)
          break
        end
      end
    end

    # Generate tokens for any challenges that don't have one
    Challenge.where(invitation_token: nil).find_each do |challenge|
      loop do
        token = SecureRandom.alphanumeric(6)
        unless Challenge.exists?(invitation_token: token)
          challenge.update_column(:invitation_token, token)
          break
        end
      end
    end
  end

  def down
    # No need to remove tokens on rollback
  end
end
