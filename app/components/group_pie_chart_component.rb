class GroupPieChartComponent < ViewComponent::Base
  def initialize(group:, day:)
    @group = group
    @day = day
    @pie_data = PieDataFromGroupDay.new(group, day).pie_data
  end

  def call
    content_tag(:div, class: 'group-pie-chart') do
      render_chart
    end
  end

  private

  def total_check_ins
    @pie_data.count { |data| data[:check_in] }
  end

  def pie_chart_data
    @pie_data.map do |data|
      [data[:name], data[:check_in] ? 1 : 0]
    end
  end

  def render_chart
    pie_chart pie_chart_data, donut: true, legend: "right", title: "User Check-ins for #{@day}"
  end
end

