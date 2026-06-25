module Api
  # Shared authentication for the read-only challenge API. Resolves the
  # challenge that owns the API key presented in the `Authorization: Bearer`
  # header. A key is scoped to a single challenge.
  module ApiKeyAuthentication
    extend ActiveSupport::Concern

    private

    # The challenge whose API key was presented, or nil when absent/invalid.
    def api_key_challenge
      return @api_key_challenge if defined?(@api_key_challenge)

      @api_key_challenge = bearer_token.present? ? Challenge.find_by(api_key: bearer_token) : nil
    end

    def bearer_token
      request.authorization.to_s[/\ABearer\s+(.+)\z/i, 1]
    end

    def render_invalid_api_key
      render json: { error: "Invalid or missing API key" }, status: :unauthorized
    end
  end
end
