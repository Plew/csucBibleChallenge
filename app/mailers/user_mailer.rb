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
    @version = @user.version.presence || "ESV"

    @chapters = @readings.map do |r|
      book_name = ApplicationController.helpers.book_number_to_name(r.book_number)
      title = "#{book_name} #{r.chapter_number}"

      # Fetch verses using centralized, language-aware VerseFetcher
      result = VerseFetcher.fetch_with_version(
        version: @version,
        book_number: r.book_number,
        chapter_number: r.chapter_number
      )

      {
        reading: r,
        title: title,
        book_name: book_name,
        chapter_number: r.chapter_number,
        version: result[:version] || @version,
        verses: result[:verses]
      }
    end

    @reading_title = @chapters.map { |c| c[:title] }.join(", ")
    @book_name = @chapters.first&.dig(:book_name)
    @chapter_number = @chapters.first&.dig(:chapter_number)

    mail(to: user.email, subject: "Bible Reading: #{@reading_title}")
  end
end
