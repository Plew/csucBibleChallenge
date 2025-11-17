class Admin::ChallengeTransfersController < Admin::BaseController
  def new
    @challenges = Challenge.all.order(:name)
  end

  def create
    from_challenge = Challenge.find(params[:from_challenge_id])
    to_challenge = Challenge.find(params[:to_challenge_id])

    service = ChallengeTransferService.new(from_challenge, to_challenge)

    if service.call
      if service.errors.any?
        redirect_to admin_change_challenge_path, alert: service.error_message
      else
        redirect_to admin_change_challenge_path, notice: service.success_message
      end
    else
      redirect_to admin_change_challenge_path, alert: service.errors.join('; ')
    end
  end
end
