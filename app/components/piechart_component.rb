# frozen_string_literal: true

class PiechartComponent < ViewComponent::Base

  READ_COLOR = 'rgba(255, 0, 0, 0.8)'
  UNREAD_COLOR = 'rgba(0, 0, 255, 0.8)'

  def initialize(
    group_id: nil, 
    title: '',
    user_checkin_data: []
    )
    @title = title
    @group_id = group_id
    @user_checkin_data = user_checkin_data
  end

  def pie_chart_data_object
    {
      labels: names_as_labels,
      datasets: [
        {
          data: checked_in_values,
          backgroundColor: background_colors,
          borderColor: border_colors,
          borderWidth: 1
        }
      ]
    }
  end

  def donut_chart_data
    pie_chart_data_object
  end

  private

  def names_as_labels
    @user_checkin_data.map { |data| data[:name] }
  end

  def checked_in_values
    # all values should be 1
    @user_checkin_data.map { |data| 1 }
  end

  def background_colors
    @user_checkin_data.map { |data| data[:checked_in_value] == 1 ? READ_COLOR : UNREAD_COLOR }
  end

  def border_colors
    @user_checkin_data.map { |data| data[:checked_in_value] == 1 ? READ_COLOR : UNREAD_COLOR }
  end

end