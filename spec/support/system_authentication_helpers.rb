module SystemAuthenticationHelpers
  def system_login_as(user, password: "password123")
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Log In"
  end
end

RSpec.configure do |config|
  config.include SystemAuthenticationHelpers, type: :system
end
