class Api::BaseController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  # Common API concerns can go here, e.g.:
  # - Authentication (ensure user is logged in for most endpoints)
  # - Authorization (ensure user has permission for an action)
  # - Error handling (standardized JSON error responses)

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protect_from_forgery with: :null_session

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def record_not_found(error)
    render json: { error: error.message }, status: :not_found
  end
end 