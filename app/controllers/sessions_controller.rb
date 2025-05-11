class SessionsController < ApplicationController
  # GET /users/sign_in
  def new
    # If already logged in, perhaps redirect to root_path
    redirect_to root_path, notice: "You are already logged in." if logged_in?
  end

  # POST /users/sign_in
  def create
    user = User.find_by(email: params[:session][:email].try(:downcase))
    # Using .try(:downcase) to avoid error if email is nil

    if user && user.authenticate(params[:session][:password])
      log_in user
      # TODO: Implement remember me functionality if params[:session][:remember_me] == '1'
      redirect_to root_path
    else
      flash.now[:alert] = 'Invalid email/username or password combination'
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /users/sign_out
  def destroy
    log_out if logged_in?
    redirect_to root_url, notice: 'Logged out!'
  end
end 