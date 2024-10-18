# frozen_string_literal: true

class PiechartComponentPreview < ViewComponent::Preview
  def default
    render(PiechartComponent.new(group_id: 1, title: 'foo'))
  end

  # You can add more preview methods here to showcase different states or variations
  # def with_data
  #   render(PiechartComponent.new(data: [30, 50, 20]))
  # end

  # def with_custom_colors
  #   render(PiechartComponent.new(colors: ['#FF5733', '#33FF57', '#3357FF']))
  # end
end