class Profile::BaseController < ApplicationController
  before_action :require_login
  
  private
  
  def current_user_enrollment
    @current_user_enrollment ||= current_user.user_challenge_enrollments.first
  end
end