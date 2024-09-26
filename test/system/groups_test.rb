require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "Creating a new group" do
    visit groups_path

    find("#create-group").click

    assert_field "Name", with: "New Name"

    fill_in "Group Name", with: "New Group"
    click_button "Create Group"

    # assert_text "New Group"
  end
end
