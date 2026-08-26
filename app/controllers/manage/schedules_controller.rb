# frozen_string_literal: true

class Manage::SchedulesController < Manage::BaseController
  def edit
    @readings = @challenge.readings.order(:scheduled_date, :book_number, :chapter_number).limit(15)
  end

  def update
    if @challenge.update(schedule_params)
      RescheduleChallengeReadings.call(@challenge)
      redirect_to edit_challenge_manage_schedule_path(@challenge), notice: t("manage.schedule.updated", default: "Schedule updated and readings rescheduled successfully.")
    else
      @readings = @challenge.readings.order(:scheduled_date, :book_number, :chapter_number).limit(15)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def schedule_params
    permitted = params.require(:challenge).permit(
      :start_date, :chapters_per_day, reading_days: [], skip_days_of_week: [], skip_dates: []
    )

    if params[:challenge][:reading_days].present?
      reading_days = params[:challenge][:reading_days].reject(&:blank?).map(&:to_i)
      all_days = [ 0, 1, 2, 3, 4, 5, 6 ]
      permitted[:skip_days_of_week] = all_days - reading_days
      permitted.delete(:reading_days)
    elsif permitted[:skip_days_of_week].present?
      permitted[:skip_days_of_week] = permitted[:skip_days_of_week].reject(&:blank?).map(&:to_i)
    elsif params[:challenge].key?(:reading_days)
      # All reading days unchecked means all days skipped
      permitted[:skip_days_of_week] = [ 0, 1, 2, 3, 4, 5, 6 ]
    else
      permitted[:skip_days_of_week] = []
    end

    if params[:challenge][:skip_dates_text].present?
      dates = params[:challenge][:skip_dates_text].split(/[\n,;]+/).map(&:strip).reject(&:blank?)
      parsed_dates = dates.map { |d| (Date.parse(d) rescue nil) }.compact.map(&:to_s)
      permitted[:skip_dates] = parsed_dates
    elsif params[:challenge].key?(:skip_dates_text)
      permitted[:skip_dates] = []
    end

    permitted
  end
end
