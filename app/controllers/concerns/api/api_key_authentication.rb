module Api
  # Shared authentication for the read-only challenge API. Resolves the
  # challenge that owns the API key presented in the `Authorization: Bearer`
  # header. A key is scoped to a single challenge.
  module ApiKeyAuthentication
    extend ActiveSupport::Concern

    private

    # Sets @challenge when a valid key for `expected_id` is presented; otherwise
    # renders 401 (missing/invalid key) or 403 (key belongs to another challenge).
    def authenticate_api_challenge!(expected_id)
      challenge = api_key_challenge

      if challenge.nil?
        render_invalid_api_key
      elsif challenge.id.to_s != expected_id.to_s
        render json: { error: "API key is not valid for this challenge" }, status: :forbidden
      else
        @challenge = challenge
      end
    end

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
