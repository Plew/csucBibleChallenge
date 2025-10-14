class Admin::ChallengeTransfersController < Admin::BaseController
  def new
    @challenges = Challenge.all.order(:name)
  end

  def create
    from_challenge = Challenge.find(params[:from_challenge_id])
    to_challenge = Challenge.find(params[:to_challenge_id])

    if params[:from_challenge_id] == params[:to_challenge_id]
      redirect_to admin_change_challenge_path, alert: 'Cannot transfer to the same challenge.'
      return
    end

    transferred_count = 0
    skipped_count = 0
    errors = []

    from_challenge.user_challenge_enrollments.each do |enrollment|
      user = enrollment.user

      # Check if user is already enrolled in the target challenge
      existing_enrollment = UserChallengeEnrollment.find_by(
        user_id: user.id,
        challenge_id: to_challenge.id
      )

      if existing_enrollment
        # User already enrolled in target challenge, just destroy the old enrollment
        enrollment.destroy
        skipped_count += 1
      else
        # Transfer the enrollment to the new challenge
        if enrollment.update(challenge_id: to_challenge.id)
          transferred_count += 1
        else
          errors << "Failed to transfer #{user.name}: #{enrollment.errors.full_messages.join(', ')}"
        end
      end
    end

    if errors.any?
      redirect_to admin_change_challenge_path,
                  alert: "Transfer completed with errors. #{transferred_count} transferred, #{skipped_count} skipped. Errors: #{errors.join('; ')}"
    else
      redirect_to admin_change_challenge_path,
                  notice: "Successfully transferred #{transferred_count} users. #{skipped_count} users were already enrolled in the target challenge."
    end
  end
end
