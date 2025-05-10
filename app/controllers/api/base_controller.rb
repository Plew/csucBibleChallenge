class Api::BaseController < ActionController::API
  # Common API concerns can go here, e.g.:
  # - Authentication (ensure user is logged in for most endpoints)
  # - Authorization (ensure user has permission for an action)
  # - Error handling (standardized JSON error responses)

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found(error)
    render json: { error: error.message }, status: :not_found
  end
end 