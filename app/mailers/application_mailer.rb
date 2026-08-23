class ApplicationMailer < ActionMailer::Base
  default from: "noreply@andgodsaid.org"
  layout "mailer"

  helper_method :unsubscribe_url_for

  def unsubscribe_url_for(user)
    token = user.create_unsubscribe_digest
    unsubscribe_url(token)
  end
end
