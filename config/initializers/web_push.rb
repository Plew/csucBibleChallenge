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
