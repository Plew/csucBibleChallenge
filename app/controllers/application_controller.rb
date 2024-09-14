class ApplicationController < ActionController::Base
  before_action :set_current_date
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

  def current_date
    @current_date ||= begin
      if cookies[:current_date].present?
        Date.parse(cookies[:current_date])
      else
        Date.today
      end
    end
  end

  def current_date_string
    @current_date_string ||= current_date.strftime('%Y-%m-%d')
  end

  private

  def set_current_date
    Current.date = current_date
    Current.date_string = current_date_string
  end

end
