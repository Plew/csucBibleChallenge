class ProfileController < ApplicationController
  before_action :require_login

  # GET /profile
  def index
    @user = current_user
  end
end