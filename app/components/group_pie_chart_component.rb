class GroupPieChartComponent < ViewComponent::Base
  def initialize(pie_chart_data)
    # array of hashes with keys :name, :recorded_on
    @pie_size = pie_chart_data.size
    @labels = pie_chart_data.map { |data| data[:name] }
    @recorded_ons = pie_chart_data.map { |data| data[:recorded_on] }
    @ones = @pie_size.times.map { 1 }
    @background_colors = @recorded_ons.map { |recorded_on| background_color(recorded_on) }
    @border_colors = @pie_size.times.map { 'rgba(0, 0, 0, 1)' }
  end

  def pie_chart_data_object
    {
      labels: @labels,
      datasets: [
        {
          data: @ones,
          backgroundColor: @background_colors,
          borderColor: @border_colors,
          borderWidth: 1
        }
      ]
    }
  end

  private

  def background_color(recorded_on)
    recorded_on.present? ? 'rgba(255, 0, 0, 0.8)' : 'rgba(0, 0, 255, 0.8)'
  end


end

