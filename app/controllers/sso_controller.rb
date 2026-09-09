require "openssl"
require "base64"
require "json"
require "uri"

class SsoController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :login ]

  # Inbound SSO: External parent app embeds or redirects with a signed JWT token
  # GET/POST /auth/sso/login
  def login
    token = extract_token

    if token.blank?
      redirect_to new_user_session_path, alert: "SSO token is missing."
      return
    end

    # Look up campus connection to use campus-specific secret if paired
    connection = find_campus_connection_for(token)
    secret = connection&.sso_secret.presence || sso_secret

    result = decode_jwt(token, secret)

    if result == :expired
      redirect_to new_user_session_path, alert: "SSO token has expired. Please launch again from your parent app."
      return
    elsif result.blank?
      redirect_to new_user_session_path, alert: "Invalid SSO token or signature."
      return
    end

    payload = result
    email = payload["email"].to_s.strip.downcase

    if email.blank?
      redirect_to new_user_session_path, alert: "SSO token must include an email address."
      return
    end

    user = find_or_create_sso_user(payload)

    # Auto-enroll in challenge if challenge_id or invitation_token is provided, or fallback to paired campus challenge
    challenge_identifier = payload["challenge_id"] ||
                           params[:challenge_id] ||
                           payload["invitation_token"] ||
                           params[:invitation_token] ||
                           connection&.challenge_id

    enroll_user_in_challenge(user, challenge_identifier) if challenge_identifier.present?

    # Set embedded mode if requested in params or JWT payload
    if params[:embed].present? ? [ "true", "1" ].include?(params[:embed].to_s.downcase) : payload["embed"]
      session[:embedded] = true
    end

    # Log in the user
    log_in user

    # Determine destination URL
    target_path = params[:return_to].presence || payload["return_to"].presence || reading_path
    safe_destination = sanitize_return_to(target_path)

    # Append embed param if in embedded mode and not already present
    if session[:embedded] && !safe_destination.include?("embed=")
      separator = safe_destination.include?("?") ? "&" : "?"
      safe_destination = "#{safe_destination}#{separator}embed=true"
    end

    redirect_to safe_destination, notice: "Signed in successfully via SSO."
  end

  # Outbound SSO: csucBibleChallenge generates a JWT token and redirects back to parent app
  # GET /auth/sso/authorize or GET /auth/sso
  def authorize
    return_to = params[:return_to] || root_url

    if logged_in?
      payload = {
        sub: current_user.id.to_s,
        email: current_user.email,
        name: current_user.username.presence || current_user.email.split("@").first,
        role: current_user.try(:role) || "member",
        iat: Time.current.to_i,
        exp: (Time.current + 1.hour).to_i
      }

      connection = find_campus_connection_by_url(return_to) || find_campus_connection_by_url(params[:hub_url])
      secret = connection&.sso_secret.presence || sso_secret

      token = encode_jwt(payload, secret)
      separator = return_to.include?("?") ? "&" : "?"
      redirect_to "#{return_to}#{separator}token=#{token}", allow_other_host: true
    else
      session[:sso_return_to] = return_to
      redirect_to new_user_session_path, notice: "Please sign in to connect your account to Campus Hub."
    end
  end

  private

  def sso_secret
    ENV["EXTERNAL_SSO_SECRET"].presence ||
      Rails.application.credentials.dig(:sso, :secret) ||
      Rails.application.credentials.dig(:external_sso_secret) ||
      "test_sso_secret_key_12345"
  end

  def extract_token
    params[:token].presence ||
      params[:jwt].presence ||
      request.headers["Authorization"]&.sub(/^Bearer\s+/i, "")&.strip
  end

  def peek_jwt_payload(token)
    parts = token.to_s.strip.split(".")
    return {} unless parts.length == 3

    payload_raw = Base64.urlsafe_decode64(parts[1]) rescue nil
    return {} unless payload_raw

    parsed = JSON.parse(payload_raw) rescue {}
    parsed.is_a?(Hash) ? parsed : {}
  end

  def find_campus_connection_for(token)
    unverified = peek_jwt_payload(token)

    candidate_urls = [
      unverified["campus_url"],
      unverified["hub_url"],
      unverified["iss"],
      params[:hub_url],
      params[:campus_url],
      request.headers["Origin"],
      (URI.parse(request.headers["Referer"]).origin rescue nil)
    ].compact.map { |u| u.to_s.strip.sub(%r{/+\z}, "") }.reject(&:blank?)

    return nil if candidate_urls.empty?

    CampusConnection.where("LOWER(hub_url) IN (?)", candidate_urls.map(&:downcase)).first
  end

  def find_campus_connection_by_url(url)
    return nil if url.blank?
    parsed_origin = URI.parse(url).origin rescue nil
    candidate = (parsed_origin || url).to_s.strip.sub(%r{/+\z}, "")
    CampusConnection.find_by("LOWER(hub_url) = ?", candidate.downcase)
  end

  def encode_jwt(payload, secret)
    header = Base64.urlsafe_encode64({ alg: "HS256", typ: "JWT" }.to_json, padding: false)
    body = Base64.urlsafe_encode64(payload.to_json, padding: false)
    sig = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("sha256", secret, "#{header}.#{body}"), padding: false)
    "#{header}.#{body}.#{sig}"
  end

  def decode_jwt(token, secret)
    parts = token.to_s.strip.split(".")
    return nil unless parts.length == 3

    header_raw = Base64.urlsafe_decode64(parts[0]) rescue nil
    payload_raw = Base64.urlsafe_decode64(parts[1]) rescue nil
    return nil unless header_raw && payload_raw

    header = JSON.parse(header_raw) rescue nil
    return nil unless header.is_a?(Hash) && header["alg"] == "HS256"

    expected_sig = Base64.urlsafe_encode64(
      OpenSSL::HMAC.digest("sha256", secret, "#{parts[0]}.#{parts[1]}"),
      padding: false
    )

    return nil unless Rack::Utils.secure_compare(expected_sig, parts[2])

    payload = JSON.parse(payload_raw) rescue nil
    return nil unless payload.is_a?(Hash)

    if payload["exp"] && Time.current.to_i > payload["exp"].to_i
      return :expired
    end

    payload
  end

  def find_or_create_sso_user(payload)
    email = payload["email"].to_s.strip.downcase
    user = User.find_by("LOWER(email) = ?", email)
    return user if user.present?

    # Auto-provision new user
    display_name = (payload["name"].presence || payload["username"].presence || email.split("@").first).to_s.strip
    base_username = display_name.gsub(/[^a-zA-Z0-9_]/, "_").squeeze("_").sub(/\A_+/, "").sub(/_+\z/, "")
    base_username = "user" if base_username.blank?
    base_username = base_username[0..18]

    candidate_username = base_username
    while User.exists?(username: candidate_username)
      candidate_username = "#{base_username}_#{SecureRandom.hex(2)}"
    end

    User.create!(
      email: email,
      username: candidate_username,
      password: SecureRandom.hex(16),
      version: "ESV",
      daily_email: true,
      daily_email_hour: 6
    )
  end

  def enroll_user_in_challenge(user, identifier)
    challenge = Challenge.find_by(id: identifier) || Challenge.find_by(invitation_token: identifier)
    return unless challenge

    unless user.challenges.include?(challenge)
      user.user_challenge_enrollments.create(challenge: challenge)
    end
    set_active_challenge(challenge)
  end

  def sanitize_return_to(path)
    return reading_path if path.blank?
    # Ensure local path only (no schema, no double slash for protocol-relative URLs)
    if path.start_with?("/") && !path.start_with?("//")
      path
    else
      reading_path
    end
  end
end
