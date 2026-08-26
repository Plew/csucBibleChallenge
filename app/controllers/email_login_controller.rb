class EmailLoginController < ApplicationController
  # GET /email_login/:token
  def show
    @token = EmailLoginToken.find_by(token: params[:token])

    if @token.nil?
      redirect_to root_path, alert: "Invalid login link."
      return
    end

    unless @token.valid_for_login?
      redirect_to root_path, alert: "This login link has expired."
      return
    end

    # Mark the token as clicked
    @token.mark_as_clicked!

    # Log the user in and set active challenge
    log_in @token.user
    set_active_challenge(@token.challenge) if @token.challenge.present?

    # Redirect to reading page for this reading's scheduled date
    target_date = @token.reading&.scheduled_date
    redirect_to reading_path(date: target_date), notice: "You've been logged in successfully."
  end
end
