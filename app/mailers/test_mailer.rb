class TestMailer < ApplicationMailer
  def simple_test(email = "test@example.com")
    @timestamp = Time.current.strftime("%B %d, %Y at %I:%M %p")

    mail(
      to: email,
      subject: "Test Email - #{@timestamp}"
    )
  end
end
