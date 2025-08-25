class ApplicationController < ActionController::Base
  before_action :set_locale
  helper_method :current_user, :logged_in?

  private

  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end

  def extract_locale
    parsed_locale = params[:locale] || cookies[:locale]
    I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : nil
  end

  # Placeholder for current_user
  # In a real app, this would involve session management (e.g., session[:user_id])
  def current_user
    # For now, simulate a logged-in user if a user exists in the DB
    # Or, more simply, track via a session variable after login.
    # This is a VERY basic placeholder for demonstration.
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def log_in(user)
    session[:user_id] = user.id # Basic session-based login
    @current_user = user
  end

  def log_out
    session.delete(:user_id)
    @current_user = nil
  end

  def require_login
    unless logged_in?
      redirect_to new_user_session_path
    end
  end
end