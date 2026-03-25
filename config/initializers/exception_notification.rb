# frozen_string_literal: true

require "exception_notification/rails"

ExceptionNotification.configure do |config|
  config.ignored_exceptions += %w[
    ActionController::RoutingError
    ActionController::InvalidAuthenticityToken
  ]

  if Rails.env.production?
    config.add_notifier(:email, {
      email_prefix: "[CSM Bible Challenge] ",
      sender_address: %("CSM Bible Challenge Errors" <noreply@mail.csmbiblechallenge.com>),
      exception_recipients: %w[pdbradley@gmail.com]
    })
  end
end
