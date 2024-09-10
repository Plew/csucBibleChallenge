class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def current_device_id
    session[:device_id] ||= SecureRandom.uuid
  end

  def current_device
    @current_device ||= Device.find_or_create_by(device_id: current_device_id)
  end

  def current_user
    @current_user ||= current_device.user || User.create!.tap { |user| user.devices << current_device }
  end
end
