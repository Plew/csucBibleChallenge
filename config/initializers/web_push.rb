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

# In development/test, ensure persistent VAPID keys so they do not change on every server restart
if Rails.application.config.webpush.vapid_public_key.blank? && (Rails.env.development? || Rails.env.test?)
  dev_key_file = Rails.root.join("tmp", "dev_vapid_keys.json")
  if File.exist?(dev_key_file)
    begin
      saved = JSON.parse(File.read(dev_key_file))
      Rails.application.config.webpush.vapid_public_key = saved["public_key"]
      Rails.application.config.webpush.vapid_private_key = saved["private_key"]
    rescue StandardError => e
      Rails.logger.warn("Could not read dev_vapid_keys.json: #{e.message}")
    end
  end

  if Rails.application.config.webpush.vapid_public_key.blank?
    dev_keys = WebPush.generate_key
    Rails.application.config.webpush.vapid_public_key = dev_keys.public_key
    Rails.application.config.webpush.vapid_private_key = dev_keys.private_key
    FileUtils.mkdir_p(Rails.root.join("tmp"))
    File.write(dev_key_file, JSON.generate({ public_key: dev_keys.public_key, private_key: dev_keys.private_key }))
  end
  Rails.application.config.webpush.vapid_subject = "mailto:dev@andgodsaid.org"
end
