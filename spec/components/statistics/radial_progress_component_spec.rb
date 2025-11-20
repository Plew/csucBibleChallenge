require 'rails_helper'

RSpec.describe Statistics::RadialProgressComponent, type: :component do
  describe "rendering" do
    it "renders with basic percentage and label" do
      render_inline(described_class.new(
        percentage: 75,
        label: "Test Progress",
        color: "accent"
      ))

      expect(page).to have_css('.radial-progress.text-accent[style*="--value:75"]')
      expect(page).to have_css('.radial-progress[style*="--size:7rem"]')
      expect(page).to have_css('.radial-progress[style*="--thickness:0.5rem"]')
      expect(page).to have_text("75%")
      expect(page).to have_text("Test Progress")
    end

    it "renders with zero percentage" do
      render_inline(described_class.new(
        percentage: 0,
        label: "No Progress",
        color: "info"
      ))

      expect(page).to have_css('.radial-progress.text-info[style*="--value:0"]')
      expect(page).to have_text("0%")
      expect(page).to have_text("No Progress")
    end

    it "renders with full completion" do
      render_inline(described_class.new(
        percentage: 100,
        label: "Complete",
        color: "accent"
      ))

      expect(page).to have_css('.radial-progress[style*="--value:100"]')
      expect(page).to have_text("100%")
      expect(page).to have_text("Complete")
    end

    it "uses info color class when specified" do
      render_inline(described_class.new(
        percentage: 50,
        label: "Half way",
        color: "info"
      ))

      expect(page).to have_css('.radial-progress.text-info')
    end

    it "uses accent color class when specified" do
      render_inline(described_class.new(
        percentage: 50,
        label: "Half way",
        color: "accent"
      ))

      expect(page).to have_css('.radial-progress.text-accent')
    end

    it "defaults to accent color for unknown color" do
      render_inline(described_class.new(
        percentage: 50,
        label: "Half way",
        color: "unknown"
      ))

      expect(page).to have_css('.radial-progress.text-accent')
    end
  end
end
