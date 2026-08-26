class TestPush
  # Send a test push notification to a user by email or username.
  #
  # Usage from rails console:
  #   TestPush.send("pdbradley@gmail.com")
  #   TestPush.send("Phil")
  #   TestPush.send("pdbradley@gmail.com", title: "Hello", body: "This is a test")
  #
  def self.send(identifier, title: "Test Notification", body: "Push notifications are working!")
    user = User.find_by(email: identifier) || User.find_by(username: identifier)
    raise "User not found: #{identifier}" unless user

    subscriptions = user.push_subscriptions
    raise "No push subscriptions for #{user.username} (#{user.email})" if subscriptions.empty?

    vapid = {
      subject: Rails.application.config.webpush.vapid_subject || "mailto:admin@andgodsaid.org",
      public_key: Rails.application.config.webpush.vapid_public_key,
      private_key: Rails.application.config.webpush.vapid_private_key
    }

    results = []
    subscriptions.each do |subscription|
      WebPush.payload_send(
        message: { title: title, options: { body: body, icon: "/icons/icon-192x192.png", data: { path: "/" } } }.to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: vapid
      )
      results << "Sent to subscription ##{subscription.id}"
    rescue WebPush::ExpiredSubscription
      subscription.destroy
      results << "Subscription ##{subscription.id} expired and was removed"
    rescue WebPush::Error => e
      results << "Failed for subscription ##{subscription.id}: #{e.message}"
    end

    results
  end
end
