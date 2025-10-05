class UserMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user, token)
    @user = user
    @token = token
    mail(to: user.email, subject: "Password Reset - CSM Bible Challenge")
  end

  def daily_reading(user, reading, login_token)
    @user = user
    @reading = reading
    @login_token = login_token
    @book_name = ApplicationController.helpers.book_number_to_name(reading.book_number)
    @chapter_number = reading.chapter_number
    @reading_title = "#{@book_name} #{@chapter_number}"

    mail(to: user.email, subject: "Bible Reading: #{@reading_title}")
  end
end
