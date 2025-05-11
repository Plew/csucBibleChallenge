class SessionsController < ApplicationController
  # GET /users/sign_in
  def new
    # Typically, no instance variable is needed for a login form
    # unless you're re-displaying it with an error message
    # and need to pre-fill something (which is rare for login).
  end

  # POST /users/sign_in
  # def create
  #   user = User.find_by(email: params[:session][:email].downcase)
  #   if user && user.authenticate(params[:session][:password])
  #     # Log the user in and redirect to the user's show page or a dashboard.
  #     log_in user # You'll need a log_in helper method in ApplicationController or a concern
  #     remember user if params[:session][:remember_me] == '1' # You'll need a remember helper
  #     redirect_to root_path, notice: 'Logged in successfully!'
  #   else
  #     # Create an error message.
  #     flash.now[:alert] = 'Invalid email/password combination'
  #     render :new, status: :unprocessable_entity
  #   end
  # end

  # DELETE /users/sign_out
  # def destroy
  #   log_out if logged_in? # You'll need log_out and logged_in? helpers
  #   redirect_to root_url, notice: 'Logged out!'
  # end
end 