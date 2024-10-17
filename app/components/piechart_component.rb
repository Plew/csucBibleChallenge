# frozen_string_literal: true

class PiechartComponent < ViewComponent::Base

  READ_COLOR = 'rgba(255, 0, 0, 0.8)'
  UNREAD_COLOR = 'rgba(0, 0, 255, 0.8)'

  def initialize(title: '')
    @title = title
    # Add any necessary initialization logic
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


end

# class GroupPieChartComponent < ViewComponent::Base
#   def initialize(pie_chart_data)
#     # array of hashes with keys :name, :recorded_on
#     @pie_size = pie_chart_data.size
#     @labels = pie_chart_data.map { |data| data[:name] }
#     @recorded_ons = pie_chart_data.map { |data| data[:recorded_on] }
#     @ones = @pie_size.times.map { 1 }
#     @background_colors = @recorded_ons.map { |recorded_on| background_color(recorded_on) }
#     @border_colors = @pie_size.times.map { 'rgba(0, 0, 0, 1)' }
#   end


#   private

#   def background_color(recorded_on)
#     recorded_on.present? ? 'rgba(255, 0, 0, 0.8)' : 'rgba(0, 0, 255, 0.8)'
#   end


# end

