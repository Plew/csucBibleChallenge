require 'rails_helper'

RSpec.describe Challenge, type: :model do
  describe "verse_comments_enabled attribute" do
    it "defaults to true" do
      challenge = create(:challenge)
      expect(challenge.verse_comments_enabled).to eq(true)
    end

    it "can be set to false" do
      challenge = create(:challenge, verse_comments_enabled: false)
      expect(challenge.verse_comments_enabled?).to eq(false)
    end
  end
end
