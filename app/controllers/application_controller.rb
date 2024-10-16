class ApplicationController < ActionController::Base
  before_action :set_active_date
  before_action :set_current_date

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  helper_method :current_user

  def current_device
    @current_device ||= Device.find_or_create_by(device_id: current_device_id)
  end

  def current_user
    @current_user ||= current_device.user || User.create!.tap { |user| user.devices << current_device }
  end

  def current_date
    # this cookie is set by application.js when the page is loaded
    cookies[:current_date] ||= Date.today
    cookies[:current_date].is_a?(Date) ? cookies[:current_date] : Date.parse(cookies[:current_date])
  end

  def active_date
    # set to today if no cookie
    cookies[:active_date] ||= Date.today
    cookies[:active_date].is_a?(Date) ? cookies[:active_date] : Date.parse(cookies[:active_date])
  end

  private

  def current_device_id
    session[:device_id] ||= SecureRandom.uuid
  end

  def set_active_date
    Current.active_date = active_date
  end

  def set_current_date
    Current.current_date = current_date
  end

end