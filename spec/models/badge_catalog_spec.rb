# frozen_string_literal: true

require "rails_helper"

RSpec.describe BadgeCatalog do
  describe ".all" do
    it "returns all badges" do
      expect(BadgeCatalog.all.size).to eq(15)
    end

    it "returns frozen array" do
      expect(BadgeCatalog.all).to be_frozen
    end
  end

  describe ".find" do
    it "returns badge by key" do
      badge = BadgeCatalog.find("chapters_50")
      expect(badge.key).to eq("chapters_50")
      expect(badge.category).to eq("chapters")
      expect(badge.threshold).to eq(50)
    end

    it "returns nil for unknown key" do
      expect(BadgeCatalog.find("nonexistent")).to be_nil
    end
  end

  describe ".by_category" do
    it "returns badges for a category" do
      streaks = BadgeCatalog.by_category("streak")
      expect(streaks.size).to eq(3)
      expect(streaks.map(&:key)).to contain_exactly("streak_7", "streak_30", "streak_50")
    end
  end

  describe ".keys" do
    it "returns all badge keys" do
      expect(BadgeCatalog.keys).to include("chapters_50", "streak_7", "verse_lover")
      expect(BadgeCatalog.keys.size).to eq(15)
    end
  end

  describe "key uniqueness" do
    it "has no duplicate keys" do
      keys = BadgeCatalog.all.map(&:key)
      expect(keys.uniq.size).to eq(keys.size)
    end
  end

  describe "i18n coverage" do
    BadgeCatalog.keys.each do |key|
      it "has English name for #{key}" do
        expect(I18n.t("badges.#{key}.name", locale: :en)).not_to include("translation missing")
      end

      it "has German name for #{key}" do
        expect(I18n.t("badges.#{key}.name", locale: :de)).not_to include("translation missing")
      end
    end
  end
end
