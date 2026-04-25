require "rails_helper"

RSpec.describe "Cuprite smoke test", type: :system do
  it "loads the sign-in page through a real browser" do
    visit new_user_session_path

    expect(page).to have_selector("h2", text: "Log in.")
    expect(page).to have_field("Email")
    expect(page).to have_field("Password")
    expect(page).to have_button("Log In")
  end

  it "logs a user in and reaches the reading page" do
    user = create(:user)
    create(:challenge).tap do |c|
      create(:user_challenge_enrollment, user: user, challenge: c)
      create(:reading, challenge: c, scheduled_date: Date.current)
    end

    system_login_as(user)

    expect(page).to have_current_path("/reading")
    expect(page).to have_link("Group")
    expect(page).to have_link("Stats")
  end
end
