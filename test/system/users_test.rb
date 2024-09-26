require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "Updating user name" do
    visit edit_user_path

    fill_in "Name", with: "New Name"
    click_button "Change Name"

    assert_field "Name", with: "New Name"
  end
end
