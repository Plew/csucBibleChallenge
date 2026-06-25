# Self-describing discovery endpoint for the read-only challenge API.
# Authenticated by a per-challenge API key (Authorization: Bearer <key>); the
# response describes the API's endpoints and fields for the key's challenge so
# integrations can adapt to changes without being rewritten.
class Api::V1::MetaController < Api::BaseController
  include Api::ApiKeyAuthentication

  before_action :require_api_key!

  # GET /api/v1/meta
  def show
    render json: ApiMeta.new(@challenge, base_url: request.base_url).as_json
  end

  private

  def require_api_key!
    @challenge = api_key_challenge
    render_invalid_api_key unless @challenge
  end
end
