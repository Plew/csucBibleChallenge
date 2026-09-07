require "openssl"
require "base64"
require "json"

class SsoController < ApplicationController
  def authorize
    return_to = params[:return_to] || root_url

    if logged_in?
      payload = {
        sub: current_user.id.to_s,
        email: current_user.email,
        name: current_user.username.presence || current_user.email.split("@").first,
        role: current_user.try(:role) || "member",
        exp: (Time.now + 1.hour).to_i
      }

      secret = ENV.fetch("EXTERNAL_SSO_SECRET", "test_sso_secret_key_12345")

      # Build standard HS256 JWT
      header = Base64.urlsafe_encode64({ alg: "HS256", typ: "JWT" }.to_json, padding: false)
      body = Base64.urlsafe_encode64(payload.to_json, padding: false)
      sig = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("sha256", secret, "#{header}.#{body}"), padding: false)
      token = "#{header}.#{body}.#{sig}"

      separator = return_to.include?("?") ? "&" : "?"
      redirect_to "#{return_to}#{separator}token=#{token}", allow_other_host: true
    else
      session[:sso_return_to] = return_to
      redirect_to new_user_session_path, notice: "Please sign in to connect your account to Campus Hub."
    end
  end
end
