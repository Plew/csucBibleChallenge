# frozen_string_literal: true

namespace :badges do
  desc "Revoke unearned halfway_there badges from users who have not completed 50% of all scheduled readings in the challenge"
  task cleanup_unearned_halfway: :environment do
    revoked = BadgeAwarder.revoke_unearned_halfway_badges!
    puts "Cleaned up #{revoked} unearned 'halfway_there' badges."
  end
end
