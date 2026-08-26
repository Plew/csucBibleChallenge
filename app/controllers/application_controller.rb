class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :check_badge_notifications
  helper_method :current_user, :logged_in?, :current_active_challenge

  def current_active_challenge
    return nil unless logged_in?

    if session[:active_challenge_id].present?
      @current_active_challenge ||= current_user.challenges.find_by(id: session[:active_challenge_id])
    end

    @current_active_challenge ||= current_user.active_challenge

    if @current_active_challenge && session[:active_challenge_id] != @current_active_challenge.id
      session[:active_challenge_id] = @current_active_challenge.id
    end

    @current_active_challenge
  end

  def set_active_challenge(challenge_or_id)
    id = challenge_or_id.is_a?(Challenge) ? challenge_or_id.id : challenge_or_id.to_i
    session[:active_challenge_id] = id
    @current_active_challenge = nil
  end

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
    session.delete(:active_challenge_id)
    @current_user = nil
    @current_active_challenge = nil
  end

  def require_login
    unless logged_in?
      redirect_to new_user_session_path
    end
  end

  def check_badge_notifications
    return unless current_user

    cache_key = "badge_notifications/#{current_user.id}"
    badge_keys = Rails.cache.read(cache_key)
    return unless badge_keys.present?

    badge_key = badge_keys.shift
    if badge_keys.empty?
      Rails.cache.delete(cache_key)
    else
      Rails.cache.write(cache_key, badge_keys, expires_in: 1.hour)
    end

    badge = BadgeCatalog.find(badge_key)
    if badge
      flash.now[:badge] = I18n.t("badges.earned_notification", badge: I18n.t("badges.#{badge_key}.name"))
    end
  end
end
