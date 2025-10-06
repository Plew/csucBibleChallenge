class UnsubscribeController < ApplicationController
  def show
    @user = User.find_by(unsubscribe_digest: params[:token])

    unless @user&.unsubscribe_token_valid?
      flash[:danger] = "Unsubscribe link is invalid or has expired"
      redirect_to root_path
      return
    end

    # Log the user in
    log_in @user

    # Clear the unsubscribe token
    @user.update_columns(unsubscribe_digest: nil, unsubscribe_sent_at: nil)

    # Redirect to email preferences with a helpful message
    flash[:info] = "You can manage your email preferences below"
    redirect_to edit_profile_email_preferences_path
  end
end
