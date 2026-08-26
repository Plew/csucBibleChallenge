# frozen_string_literal: true

class CatchUpsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :require_enrollment

  def show
    today = Time.current.in_time_zone(@challenge.timezone).to_date

    completed_reading_ids = current_user.user_readings
                                        .joins(:reading)
                                        .where(readings: { challenge_id: @challenge.id })
                                        .select(:reading_id)

    @missed_readings = @challenge.readings
                                 .where("scheduled_date < ?", today)
                                 .where.not(id: completed_reading_ids)
                                 .order(scheduled_date: :asc)
  end

  private

  def set_challenge
    @challenge = if params[:challenge_id].present?
                   Challenge.find_by(id: params[:challenge_id])
                 else
                   current_active_challenge
                 end

    if @challenge.nil?
      redirect_to challenges_path, alert: t("catch_up.must_be_enrolled")
    end
  end

  def require_enrollment
    unless current_user.challenges.include?(@challenge)
      redirect_to challenges_path, alert: t("catch_up.must_be_enrolled")
    end
  end
end
