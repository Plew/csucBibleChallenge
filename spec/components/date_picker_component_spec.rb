require 'rails_helper'

RSpec.describe DatePickerComponent, type: :component do
  describe "Form field mode" do
    let(:challenge) { build(:challenge, start_date: Date.current) }
    let(:form) do
      view = ActionView::Base.empty
      ActionView::Helpers::FormBuilder.new(:challenge, challenge, view, {})
    end

    it "renders form date field with presets and calendar trigger" do
      render_inline(described_class.new(
        form: form,
        attribute: :start_date,
        label: "Start Date",
        target: "startDate",
        change_action: "challenge-creator#updateSchedule"
      ))

      expect(rendered_content).to include("Start Date")
      expect(rendered_content).to include("Today")
      expect(rendered_content).to include("Tomorrow")
      expect(rendered_content).to include("Next Mon")
      expect(rendered_content).to include('type="date"')
      expect(rendered_content).to include('data-challenge-creator-target="startDate"')
      expect(rendered_content).to include("click->challenge-creator#openCalendar")
    end
  end

  describe "Calendar matrix mode" do
    let(:challenge) { create(:challenge, start_date: Date.current - 5.days, end_date: Date.current + 25.days) }
    let(:user) { create(:user) }

    it "renders calendar month navigation and days" do
      render_inline(described_class.new(
        selected_date: Date.current,
        challenge: challenge,
        user: user
      ))

      expect(rendered_content).to include(Date.current.strftime("%B %Y"))
      expect(rendered_content).to include("Completed")
      expect(rendered_content).to include("Not Read")
    end
  end
end
