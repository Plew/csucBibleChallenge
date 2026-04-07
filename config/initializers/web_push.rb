Rails.application.config.webpush = ActiveSupport::OrderedOptions.new

vapid = Rails.application.credentials.dig(:vapid)

if vapid
  Rails.application.config.webpush.vapid_public_key = vapid[:public_key]
  Rails.application.config.webpush.vapid_private_key = vapid[:private_key]
end
