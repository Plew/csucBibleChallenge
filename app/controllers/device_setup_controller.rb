class DeviceSetupController < ApplicationController
  skip_before_action :set_global_browser_date

  def show
    if cookies[:browser_date].present?
      redirect_to root_path
    end
  end
end 