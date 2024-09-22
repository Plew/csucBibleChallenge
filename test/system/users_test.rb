require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "Updating user name" do
    # visit edit_user_path(users(:lone_user))
    visit edit_user_path
  
    assert_selector "h1", text: "Edit User"
  end
end
