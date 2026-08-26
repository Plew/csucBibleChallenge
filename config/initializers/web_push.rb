Rails.application.config.webpush = ActiveSupport::OrderedOptions.new

vapid = Rails.application.credentials.dig(:vapid)

if vapid
  Rails.application.config.webpush.vapid_public_key = vapid[:public_key] || ENV["VAPID_PUBLIC_KEY"]
  Rails.application.config.webpush.vapid_private_key = vapid[:private_key] || ENV["VAPID_PRIVATE_KEY"]
  Rails.application.config.webpush.vapid_subject = vapid[:subject] || ENV["VAPID_SUBJECT"] || "mailto:admin@andgodsaid.org"
else
  Rails.application.config.webpush.vapid_public_key = ENV["VAPID_PUBLIC_KEY"]
  Rails.application.config.webpush.vapid_private_key = ENV["VAPID_PRIVATE_KEY"]
  Rails.application.config.webpush.vapid_subject = ENV["VAPID_SUBJECT"] || "mailto:admin@andgodsaid.org"
end

# In development/test, ensure valid VAPID keys are always available
if Rails.application.config.webpush.vapid_public_key.blank? && (Rails.env.development? || Rails.env.test?)
  dev_keys = WebPush.generate_key
  Rails.application.config.webpush.vapid_public_key = dev_keys.public_key
  Rails.application.config.webpush.vapid_private_key = dev_keys.private_key
  Rails.application.config.webpush.vapid_subject = "mailto:dev@andgodsaid.org"
end
