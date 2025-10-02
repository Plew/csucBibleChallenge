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

      # Redirect to reading page if user has an active challenge, otherwise to challenge show page
      if user.challenges.any?
        first_challenge = user.challenges.first
        if first_challenge.start_date <= Date.current && first_challenge.end_date >= Date.current
          redirect_to reading_path
        else
          redirect_to challenge_path(first_challenge)
        end
      else
        redirect_to challenges_path
      end
    else
      flash.now[:alert] = 'Invalid email/username or password combination'
      render :new, status: :unprocessable_content
    end
  end

  # DELETE /users/sign_out
  def destroy
    log_out # Always clear session, even if invalid
    redirect_to root_url, notice: 'Logged out!'
  end
end 