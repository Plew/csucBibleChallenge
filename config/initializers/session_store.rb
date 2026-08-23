# Configure session store
Rails.application.config.session_store :cookie_store,
  key: "_andgodsaid_bible_challenge_session",
  expire_after: 2.weeks,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
