class UserMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user, token)
    @user = user
    @token = token
    mail(to: user.email, subject: "Password Reset - And God Said")
  end

  def daily_reading(user, readings_or_reading, login_token)
    @user = user
    @login_token = login_token
    @readings = Array(readings_or_reading)
    @reading = @readings.first

    titles = @readings.map do |r|
      book_name = ApplicationController.helpers.book_number_to_name(r.book_number)
      "#{book_name} #{r.chapter_number}"
    end

    @reading_title = titles.join(", ")
    @book_name = ApplicationController.helpers.book_number_to_name(@reading.book_number) if @reading
    @chapter_number = @reading.chapter_number if @reading

    mail(to: user.email, subject: "Bible Reading: #{@reading_title}")
  end
end
