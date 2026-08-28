class FallbackDeliveryMethod
  attr_accessor :settings

  def initialize(settings = {})
    @settings = settings
  end

  def deliver!(mail)
    primary_smtp = Mail::SMTP.new(settings[:primary])
    primary_smtp.deliver!(mail)
    Rails.logger.info "[ActionMailer] Successfully sent via Primary (AWS SES) to: #{mail.destinations.join(', ')}"
  rescue StandardError => e
    Rails.logger.warn "[ActionMailer] Primary (AWS SES) failed with #{e.class}: #{e.message}. Falling back to Secondary (Resend)..."

    if settings[:secondary].present?
      secondary_smtp = Mail::SMTP.new(settings[:secondary])
      secondary_smtp.deliver!(mail)
      Rails.logger.info "[ActionMailer] Successfully sent via Secondary (Resend) to: #{mail.destinations.join(', ')}"
    else
      raise e
    end
  end
end

ActionMailer::Base.add_delivery_method :fallback, FallbackDeliveryMethod
