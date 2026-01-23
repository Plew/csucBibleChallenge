# frozen_string_literal: true

class DatePickerComponentPreview < ViewComponent::Preview
  # Shows the date picker with some completed readings
  # @label Default
  def default
    challenge = Challenge.first || FactoryBot.create(:challenge)
    user = User.first || FactoryBot.create(:user)
    selected_date = Date.current

    render DatePickerComponent.new(
      selected_date: selected_date,
      challenge: challenge,
      user: user
    )
  end

  # Shows the date picker with a date in the past
  # @label Past Month
  def past_month
    challenge = Challenge.first || FactoryBot.create(:challenge)
    user = User.first || FactoryBot.create(:user)
    selected_date = Date.current - 1.month

    render DatePickerComponent.new(
      selected_date: selected_date,
      challenge: challenge,
      user: user
    )
  end

  # Shows the date picker with a date in the future
  # @label Future Month
  def future_month
    challenge = Challenge.first || FactoryBot.create(:challenge)
    user = User.first || FactoryBot.create(:user)
    selected_date = Date.current + 1.month

    render DatePickerComponent.new(
      selected_date: selected_date,
      challenge: challenge,
      user: user
    )
  end
end
