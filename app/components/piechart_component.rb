# frozen_string_literal: true

class PiechartComponent < ViewComponent::Base

  READ_COLOR = 'rgba(255, 0, 0, 0.8)'
  UNREAD_COLOR = 'rgba(0, 0, 255, 0.8)'

  def initialize(group_id: nil, title: '')
    @title = title
    @group_id = group_id
  end

  def pie_chart_data_object
    {
      labels: ['foo', 'bar'],
      datasets: [
        {
          data: [1,1],
          backgroundColor: [READ_COLOR, UNREAD_COLOR],
          borderColor: [READ_COLOR, UNREAD_COLOR],
          borderWidth: 1
        }
      ]
    }
  end

  def donut_chart_data
    pie_chart_data_object
  end

  def background_color(recorded_on)
    recorded_on.present? ? READ_COLOR : UNREAD_COLOR
  end

end