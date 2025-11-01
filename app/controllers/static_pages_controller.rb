class StaticPagesController < ApplicationController
  before_action :require_login

  def statistics_update
    # Static page - no additional logic needed
  end
end
