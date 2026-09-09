# Configure session store
# Note: For cross-site iframe embedding, SameSite must be :none and secure must be true over HTTPS.
same_site_setting = ENV.fetch("SESSION_COOKIE_SAMESITE", Rails.env.production? ? "none" : "lax").to_sym
secure_setting = Rails.env.production? || same_site_setting == :none

Rails.application.config.session_store :cookie_store,
  key: "_andgodsaid_bible_challenge_session",
  expire_after: 2.weeks,
  secure: secure_setting,
  httponly: true,
  same_site: same_site_setting
