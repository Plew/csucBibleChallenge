require "net/http"
require "json"
require "uri"

class FallbackDeliveryMethod
  attr_accessor :settings

  def initialize(settings = {})
    @settings = settings
  end

  def deliver!(mail)
    # 1. Primary: Amazon SES (HTTPS API - Port 443)
    aws_config = settings[:aws_ses] || fetch_aws_ses_config
    if aws_config.present? && aws_config[:access_key_id].present? && aws_config[:secret_access_key].present?
      begin
        deliver_via_aws_ses_api!(mail, aws_config)
        Rails.logger.info "[ActionMailer] Successfully sent via Primary (Amazon SES HTTPS API) to: #{mail.destinations.join(', ')}"
        return
      rescue StandardError => e
        Rails.logger.warn "[ActionMailer] Primary (Amazon SES HTTPS API) failed with #{e.class}: #{e.message}. Falling back to Secondary (Resend HTTPS API)..."
      end
    end

    # 2. Secondary: Resend REST API (HTTPS - Port 443)
    resend_key = settings[:resend_api_key] || Rails.application.credentials.dig(:resend, :api_key)
    if resend_key.present?
      deliver_via_resend_api!(mail, resend_key)
      Rails.logger.info "[ActionMailer] Successfully sent via Secondary (Resend HTTPS API) to: #{mail.destinations.join(', ')}"
    else
      raise "No email delivery method succeeded. Please check AWS SES and Resend credentials in Rails credentials."
    end
  end

  private

  def fetch_aws_ses_config
    creds = Rails.application.credentials
    if creds.aws&.dig(:ses, :access_key_id).present?
      {
        region: creds.aws&.dig(:ses, :region) || "us-east-1",
        access_key_id: creds.aws&.dig(:ses, :access_key_id),
        secret_access_key: creds.aws&.dig(:ses, :secret_access_key)
      }
    elsif creds.dig(:aws, :access_key_id).present?
      {
        region: creds.dig(:aws, :region) || "us-east-1",
        access_key_id: creds.dig(:aws, :access_key_id),
        secret_access_key: creds.dig(:aws, :secret_access_key)
      }
    end
  end

  def deliver_via_aws_ses_api!(mail, aws_config)
    require "aws-sdk-sesv2" unless defined?(Aws::SESV2)

    client = Aws::SESV2::Client.new(
      region: aws_config[:region] || "us-east-1",
      access_key_id: aws_config[:access_key_id],
      secret_access_key: aws_config[:secret_access_key]
    )

    client.send_email(
      content: {
        raw: {
          data: mail.to_s
        }
      },
      destination: {
        to_addresses: mail.destinations
      },
      from_email_address: mail[:from]&.to_s
    )
  end

  def deliver_via_resend_api!(mail, api_key)
    uri = URI("https://api.resend.com/emails")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    payload = {
      from: mail[:from]&.to_s || "noreply@andgodsaid.org",
      to: mail.destinations,
      subject: mail.subject
    }

    if mail.html_part
      payload[:html] = mail.html_part.body.decoded
      payload[:text] = mail.text_part&.body&.decoded if mail.text_part
    elsif mail.text_part
      payload[:text] = mail.text_part.body.decoded
    else
      payload[:html] = mail.body.decoded
    end

    payload[:cc] = Array(mail.cc) if mail.cc.present?
    payload[:bcc] = Array(mail.bcc) if mail.bcc.present?
    payload[:reply_to] = mail[:reply_to]&.to_s if mail[:reply_to].present?

    request = Net::HTTP::Post.new(uri.path, {
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json"
    })
    request.body = payload.to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise "Resend API Error (#{response.code}): #{response.body}"
    end

    response
  end
end

ActionMailer::Base.add_delivery_method :fallback, FallbackDeliveryMethod
