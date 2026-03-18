require 'rails_helper'

RSpec.describe Challenge, type: :model do
  describe "locked attribute" do
    it "defaults to false" do
      challenge = create(:challenge)
      expect(challenge.locked).to eq(false)
    end

    it "can be set to true" do
      challenge = create(:challenge, locked: true)
      expect(challenge.locked?).to eq(true)
    end
  end
end
