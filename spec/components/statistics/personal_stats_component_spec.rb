require 'rails_helper'

RSpec.describe Statistics::PersonalStatsComponent, type: :component do
  let(:user_stats) do
    {
      completion_percentage: 75,
      on_schedule_percentage: 80,
      chapters_completed: 45,
      chapters_scheduled: 60
    }
  end

  describe "rendering without sprint" do
    it "renders challenge stats only" do
      render_inline(described_class.new(
        user_stats: user_stats
      ))

      expect(page).to have_text(I18n.t('stats.personal'))
      expect(page).to have_text(I18n.t('stats.challenge_stats'))
      expect(page).to have_text("75%")
      expect(page).to have_text("80%")
      expect(page).to have_text(I18n.t('stats.chapters_read_short'))
      expect(page).to have_text(I18n.t('stats.on_time_short'))
    end

    it "does not render sprint section when no sprint data" do
      render_inline(described_class.new(
        user_stats: user_stats
      ))

      expect(page).not_to have_css('.divider')
      expect(page).not_to have_text('Sprint Stats')
    end

    it "does not render sprint section when sprint_stats is nil" do
      render_inline(described_class.new(
        user_stats: user_stats,
        sprint_stats: nil,
        current_sprint: nil
      ))

      expect(page).not_to have_css('.divider')
      expect(page).not_to have_text('Sprint Stats')
    end
  end

  describe "rendering with sprint" do
    let(:sprint) { instance_double("Sprint", title: "March Sprint") }
    let(:sprint_stats) do
      {
        completion_percentage: 90,
        on_schedule_percentage: 85,
        chapters_completed: 27,
        chapters_scheduled: 30
      }
    end

    it "renders both challenge and sprint stats" do
      render_inline(described_class.new(
        user_stats: user_stats,
        sprint_stats: sprint_stats,
        current_sprint: sprint
      ))

      # Challenge stats
      expect(page).to have_text(I18n.t('stats.challenge_stats'))
      expect(page).to have_text("75%")
      expect(page).to have_text("80%")

      # Sprint stats
      expect(page).to have_css('.divider')
      expect(page).to have_text(I18n.t('stats.sprint_stats', sprint_title: "March Sprint"))
      expect(page).to have_text("90%")
      expect(page).to have_text("85%")
      expect(page).to have_text(I18n.t('stats.chapters_read_short'))
      expect(page).to have_text(I18n.t('stats.on_time_short'))
    end

    it "does not render sprint section when current_sprint is nil" do
      render_inline(described_class.new(
        user_stats: user_stats,
        sprint_stats: sprint_stats,
        current_sprint: nil
      ))

      expect(page).not_to have_css('.divider')
      expect(page).not_to have_text('Sprint Stats')
    end

    it "does not render sprint section when sprint_stats is nil" do
      render_inline(described_class.new(
        user_stats: user_stats,
        sprint_stats: nil,
        current_sprint: sprint
      ))

      expect(page).not_to have_css('.divider')
      expect(page).not_to have_text('Sprint Stats')
    end
  end

  describe "with zero stats" do
    let(:zero_stats) do
      {
        completion_percentage: 0,
        on_schedule_percentage: 0,
        chapters_completed: 0,
        chapters_scheduled: 0
      }
    end

    it "renders with zero percentages" do
      render_inline(described_class.new(
        user_stats: zero_stats
      ))

      expect(page).to have_text("0%")
      expect(page).to have_text(I18n.t('stats.chapters_read_short'))
    end
  end

  describe "with full completion" do
    let(:full_stats) do
      {
        completion_percentage: 100,
        on_schedule_percentage: 100,
        chapters_completed: 60,
        chapters_scheduled: 60
      }
    end

    it "renders with 100% completion" do
      render_inline(described_class.new(
        user_stats: full_stats
      ))

      expect(page).to have_text("100%")
      expect(page).to have_text(I18n.t('stats.chapters_read_short'))
    end
  end

  describe "with reading history graphs" do
    let(:challenge_graph_data) do
      {
        total_days: 10,
        completed_days: [ { day: 0, on_time: true }, { day: 1, on_time: false } ],
        start_date: Date.new(2025, 1, 1),
        current_day: 2
      }
    end

    it "renders challenge graph when challenge_graph_data is provided" do
      render_inline(described_class.new(
        user_stats: user_stats,
        challenge_graph_data: challenge_graph_data
      ))

      expect(page).to have_css('.reading-history-graph')
    end

    it "does not render challenge graph when challenge_graph_data is nil" do
      render_inline(described_class.new(
        user_stats: user_stats,
        challenge_graph_data: nil
      ))

      expect(page).not_to have_css('.reading-history-graph')
    end
  end

  describe "with sprint graph data" do
    let(:sprint) { instance_double("Sprint", title: "March Sprint") }
    let(:sprint_stats) do
      {
        completion_percentage: 90,
        on_schedule_percentage: 85,
        chapters_completed: 27,
        chapters_scheduled: 30
      }
    end
    let(:sprint_graph_data) do
      {
        total_days: 5,
        completed_days: [ { day: 0, on_time: true } ],
        start_date: Date.new(2025, 3, 1),
        current_day: 1
      }
    end

    it "renders sprint graph when sprint_graph_data is provided" do
      render_inline(described_class.new(
        user_stats: user_stats,
        sprint_stats: sprint_stats,
        current_sprint: sprint,
        sprint_graph_data: sprint_graph_data
      ))

      # Should have 2 graphs: one for sprint, one for challenge (even though challenge_graph_data is nil)
      expect(page).to have_css('.reading-history-graph', count: 1)
    end

    it "does not render sprint graph when sprint_graph_data is nil" do
      render_inline(described_class.new(
        user_stats: user_stats,
        sprint_stats: sprint_stats,
        current_sprint: sprint,
        sprint_graph_data: nil
      ))

      expect(page).not_to have_css('.reading-history-graph')
    end
  end
end
