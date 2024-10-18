# frozen_string_literal: true

class PiechartComponentPreview < ViewComponent::Preview
  def two
    render(PiechartComponent.new(group_id: 1, title: 'Group X', user_checkin_data: user_checkin_data))
  end

  def nine
    render(PiechartComponent.new(group_id: 1, title: 'Group X', user_checkin_data: user_checkin_data_with_nine_users))
  end

  private

  def user_checkin_data
    [
      { name: 'John Doe', checked_in_value: 1 },
      { name: 'Jane Doe', checked_in_value: 0 }
    ]
  end

  def user_checkin_data_with_nine_users
    [
      { name: 'John Doe', checked_in_value: 1 },
      { name: 'Jane Doe', checked_in_value: 1 },
      { name: 'John Smith', checked_in_value: 0 },
      { name: 'Jane Smith', checked_in_value: 0 },
      { name: 'John Doe', checked_in_value: 1 },
      { name: 'Jane Doe', checked_in_value: 1 },
      { name: 'John Smith', checked_in_value: 0 },
      { name: 'Jane Smith', checked_in_value: 0 },
      { name: 'John Doe', checked_in_value: 1 },
      { name: 'Jane Doe', checked_in_value: 1 },
      { name: 'John Smith', checked_in_value: 0 },
      { name: 'Jane Smith', checked_in_value: 0 },
    ]
  end
end
