class UsersController < ApplicationController
  # GET /users/sign_up
  def new
    @user = User.new
    @challenge_invitation_token = params[:challenge_invitation_token] || session[:challenge_invitation_token]
    session[:challenge_invitation_token] = @challenge_invitation_token if @challenge_invitation_token
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
            redirect_to reading_path, notice: "Welcome! You've been automatically enrolled in #{challenge.name}."
            return
          end
        end
        session.delete(:challenge_invitation_token) # Clear token even if enrollment fails
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