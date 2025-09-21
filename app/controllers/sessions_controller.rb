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
      redirect_to reading_path
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