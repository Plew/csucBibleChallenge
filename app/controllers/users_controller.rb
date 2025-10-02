class UsersController < ApplicationController
  # GET /users/sign_up
  def new
    @user = User.new
    @challenge_invitation_token = params[:challenge_invitation_token] || session[:challenge_invitation_token]
    session[:challenge_invitation_token] = @challenge_invitation_token if @challenge_invitation_token

    # Store challenge_id for auto-enrollment after signup
    if params[:challenge_id].present?
      session[:pending_challenge_id] = params[:challenge_id]
    end
  end

  # POST /users
  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user # Log in the user after successful registration

      # Check for challenge invitation token and auto-enroll
      if session[:challenge_invitation_token].present?
        challenge = Challenge.find_by(invitation_token: session[:challenge_invitation_token])
        if challenge && !current_user.challenges.include?(challenge) && current_user.challenges.empty?
          enrollment = challenge.user_challenge_enrollments.new(user: current_user)
          if enrollment.save
            session.delete(:challenge_invitation_token) # Clear the token
            session.delete(:pending_challenge_id) # Clear pending challenge if any
            # Redirect to reading page if challenge has started, otherwise to challenge page
            if challenge.start_date <= Date.current && challenge.end_date >= Date.current
              redirect_to reading_path, notice: "Joined!"
            else
              redirect_to challenge_path(challenge), notice: "Joined!"
            end
            return
          end
        end
        session.delete(:challenge_invitation_token) # Clear token even if enrollment fails
      end

      # Check for pending challenge enrollment (from direct challenge page signup)
      if session[:pending_challenge_id].present?
        challenge = Challenge.find_by(id: session[:pending_challenge_id])
        if challenge && !current_user.challenges.include?(challenge) && current_user.challenges.empty?
          enrollment = challenge.user_challenge_enrollments.new(user: current_user)
          if enrollment.save
            session.delete(:pending_challenge_id) # Clear the pending challenge
            # Redirect to reading page if challenge has started, otherwise to challenge page
            if challenge.start_date <= Date.current && challenge.end_date >= Date.current
              redirect_to reading_path, notice: "Joined!"
            else
              redirect_to challenge_path(challenge), notice: "Joined!"
            end
            return
          end
        end
        session.delete(:pending_challenge_id) # Clear pending challenge even if enrollment fails
      end

      redirect_to root_path
    else
      flash[:alert] = @user.errors.full_messages.join(", ")
      @challenge_invitation_token = session[:challenge_invitation_token]
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :avatar)
  end
end 