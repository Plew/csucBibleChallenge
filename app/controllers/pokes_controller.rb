class PokesController < ApplicationController
  before_action :require_login

  def create
    @group = Group.find(params[:group_id])
    challenge = @group.challenge
    pokee = User.find(params[:pokee_id])

    today = Time.current.in_time_zone(challenge.timezone)
    today_date = today.to_date

    is_after_9pm = params[:simulate_9pm] == "true" || today.hour >= 21

    unless is_after_9pm
      redirect_to group_path(@group), alert: t("pokes.too_early")
      return
    end

    unless pokee.push_subscriptions.exists?
      redirect_to group_path(@group), alert: t("pokes.no_push")
      return
    end

    todays_reading = challenge.readings.find_by(scheduled_date: today_date)
    if todays_reading && pokee.user_readings.exists?(reading_id: todays_reading.id, completed_on: today_date)
      redirect_to group_path(@group), alert: t("pokes.already_read")
      return
    end

    poke = Poke.new(
      poker: current_user,
      pokee: pokee,
      challenge: challenge,
      poked_on: today_date
    )

    if poke.save
      SendPokeNotificationJob.perform_later(poke.id)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "poke_button_#{pokee.id}",
            partial: "pokes/poked_indicator",
            locals: { user: pokee }
          )
        end
        format.html { redirect_to group_path(@group), notice: t("pokes.success") }
      end
    else
      redirect_to group_path(@group), alert: poke.errors.full_messages.first
    end
  end
end
