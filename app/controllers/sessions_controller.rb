class SessionsController < ApplicationController
  # GET /users/sign_in
  def new
    # If already logged in, redirect to reading page
    redirect_to reading_path, notice: "You are already logged in." if logged_in?
  end

  # POST /users/sign_in
  def create
    @email = params[:session][:email].try(:downcase)
    user = User.find_by(email: @email)

    if user && user.authenticate(params[:session][:password])
      log_in user

      # Check for group invitation token and auto-enroll
      if session[:group_invitation_token].present?
        group = Group.find_by(token: session[:group_invitation_token])
        if group
          unless current_user.challenges.include?(group.challenge)
            challenge_enrollment = group.challenge.user_challenge_enrollments.new(user: current_user)
            challenge_enrollment.save
          end
          set_active_challenge(group.challenge)

          if current_user.challenges.include?(group.challenge) && !current_user.groups.include?(group)
            group_enrollment = group.user_group_enrollments.new(user: current_user)
            if group_enrollment.save
              session.delete(:group_invitation_token)
              redirect_to group_path(group), notice: "Joined #{group.name}!"
              return
            end
          end
        end
        session.delete(:group_invitation_token)
      end

      # Check for challenge invitation token and auto-enroll
      if session[:challenge_invitation_token].present?
        challenge = Challenge.find_by(invitation_token: session[:challenge_invitation_token])
        if challenge
          unless current_user.challenges.include?(challenge)
            enrollment = challenge.user_challenge_enrollments.new(user: current_user)
            enrollment.save
          end
          set_active_challenge(challenge)
          session.delete(:challenge_invitation_token)
          if challenge.start_date <= Date.current && challenge.end_date >= Date.current
            redirect_to reading_path, notice: "Joined #{challenge.name}!"
          else
            redirect_to challenge_path(challenge), notice: "Joined #{challenge.name}!"
          end
          return
        end
        session.delete(:challenge_invitation_token)
      end

      # Redirect to reading page if user has an active challenge, otherwise to challenge show page
      if user.challenges.any?
        first_challenge = current_active_challenge
        if first_challenge.start_date <= Date.current && first_challenge.end_date >= Date.current
          redirect_to reading_path
        else
          redirect_to challenge_path(first_challenge)
        end
      else
        redirect_to challenges_path
      end
    else
      flash.now[:alert] = "Invalid email/username or password combination"
      render :new, status: :unprocessable_content
    end
  end

  # DELETE /users/sign_out
  def destroy
    log_out # Always clear session, even if invalid
    redirect_to root_url, notice: "Logged out!"
  end
end
