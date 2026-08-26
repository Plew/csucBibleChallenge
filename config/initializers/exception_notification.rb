# frozen_string_literal: true

require "exception_notification/rails"

ExceptionNotification.configure do |config|
  config.ignored_exceptions += %w[
    ActionController::RoutingError
    ActionController::InvalidAuthenticityToken
  ]

  if Rails.env.production?
    config.add_notifier(:email, {
      email_prefix: "[And God Said] ",
      sender_address: %("And God Said Errors" <noreply@andgodsaid.org>),
      exception_recipients: %w[plewwatsono@gmail.com]
    })
  end
end
