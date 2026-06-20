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
      # TODO: Implement remember me functionality if params[:session][:remember_me] == '1'

      # Check for group invitation token and auto-enroll
      if session[:group_invitation_token].present?
        group = Group.find_by(token: session[:group_invitation_token])
        if group
          # Enroll in challenge if not already enrolled
          unless current_user.challenges.include?(group.challenge)
            if current_user.challenges.empty?
              challenge_enrollment = group.challenge.user_challenge_enrollments.new(user: current_user)
              challenge_enrollment.save
            end
          end

          # Enroll in group if in the challenge
          if current_user.challenges.include?(group.challenge) && !current_user.groups.include?(group)
            group_enrollment = group.user_group_enrollments.new(user: current_user)
            if group_enrollment.save
              session.delete(:group_invitation_token)
              redirect_to group_path(group), notice: "Joined!"
              return
            end
          end
        end
        session.delete(:group_invitation_token)
      end

      # Redirect to reading page if user has an active challenge, otherwise to challenge show page
      if user.challenges.any?
        first_challenge = user.active_challenge
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
