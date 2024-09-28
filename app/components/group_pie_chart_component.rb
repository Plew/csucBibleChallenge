class GroupPieChartComponent < ViewComponent::Base
  def initialize(names_and_check_ins = [])
    @names_and_check_ins = names_and_check_ins
  end

  def call
    content_tag(:div, class: 'group-pie-chart') do
      render_chart
    end
  end

  private

  def total_check_ins
    @names_and_check_ins.sum { |name_and_check_in| name_and_check_in[:check_in] ? 1 : 0 }
  end

  def pie_chart_data
    @names_and_check_ins.map do |name_and_check_in|
      [name_and_check_in[:name], name_and_check_in[:check_in].present? ? 1 : 0]
    end
  end

  def render_chart
    pie_chart pie_chart_data, donut: true, legend: "right", title: "User Check-ins"
  end
end

