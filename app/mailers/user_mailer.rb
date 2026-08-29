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

      # Attempt to fetch verses in preferred version, with fallback
      verses = r.verses(version: @version).to_a
      verses = r.verses(version: "ESV").to_a if verses.empty?
      verses = r.verses(version: "KJV").to_a if verses.empty?
      verses = Verse.where(book_number: r.book_number, chapter_number: r.chapter_number).order(:verse_number).to_a if verses.empty?

      actual_version = verses.first&.version || @version

      {
        reading: r,
        title: title,
        book_name: book_name,
        chapter_number: r.chapter_number,
        version: actual_version,
        verses: verses
      }
    end

    @reading_title = @chapters.map { |c| c[:title] }.join(", ")
    @book_name = @chapters.first&.dig(:book_name)
    @chapter_number = @chapters.first&.dig(:chapter_number)

    mail(to: user.email, subject: "Bible Reading: #{@reading_title}")
  end
end
