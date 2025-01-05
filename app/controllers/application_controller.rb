class ApplicationController < ActionController::Base
  before_action :set_global_browser_date

  if Rails.env.development?
    skip_before_action :verify_authenticity_token
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  helper_method :current_user

  def current_device
    @current_device ||= Device.find_or_create_by(device_id: current_device_id)
  end

  def current_user
    @current_user ||= current_device.user || User.create!.tap { |user| user.devices << current_device }
  end

  private

  def current_device_id
    cookies.permanent[:device_id] ||= SecureRandom.uuid
  end

  def set_global_browser_date
    if cookies[:browser_date].present?
      Current.browser_date = Date.parse(cookies[:browser_date])
    else
      redirect_to device_setup_path unless controller_name == 'device_setup'
    end
  end
end