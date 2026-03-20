# frozen_string_literal: true

require "rails_helper"

RSpec.describe BadgesDisplayComponent, type: :component do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }

  before do
    create(:user_challenge_enrollment, user: user, challenge: challenge)
  end

  it "does not render when user has no badges" do
    render_inline(described_class.new(user: user, challenge: challenge))
    expect(page).not_to have_text(I18n.t("badges.title"))
  end

  it "renders only earned badges" do
    create(:user_badge, user: user, challenge: challenge, badge_key: "chapters_50")

    render_inline(described_class.new(user: user, challenge: challenge))
    expect(page).to have_text(I18n.t("badges.chapters_50.name"))
    expect(page).not_to have_text(I18n.t("badges.chapters_100.name"))
  end

  it "renders category headers" do
    create(:user_badge, user: user, challenge: challenge, badge_key: "chapters_50")
    create(:user_badge, user: user, challenge: challenge, badge_key: "streak_7")

    render_inline(described_class.new(user: user, challenge: challenge))
    expect(page).to have_text(I18n.t("badges.chapters_50.name"))
    expect(page).to have_text(I18n.t("badges.streak_7.name"))
  end
end
