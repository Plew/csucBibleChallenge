namespace :avatars do
  desc "Regenerate all avatar variants (e.g. after changing resize strategy)"
  task regenerate_variants: :environment do
    users_with_avatars = User.joins(:avatar_attachment)
    total = users_with_avatars.count
    puts "Regenerating avatar variants for #{total} users..."

    users_with_avatars.find_each.with_index(1) do |user, index|
      user.avatar.variant(:thumb).processed
      user.avatar.variant(:medium).processed
      user.avatar.variant(:large).processed
      user.avatar.variant(:xlarge).processed
      user.avatar.variant(:xxlarge).processed
      user.avatar.variant(:profile).processed
      puts "  [#{index}/#{total}] #{user.username} - done"
    rescue => e
      puts "  [#{index}/#{total}] #{user.username} - ERROR: #{e.message}"
    end

    puts "Done!"
  end
end
