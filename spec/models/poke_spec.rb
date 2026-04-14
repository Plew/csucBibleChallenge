require "rails_helper"

RSpec.describe Poke, type: :model do
  describe "associations" do
    it { should belong_to(:poker).class_name("User") }
    it { should belong_to(:pokee).class_name("User") }
    it { should belong_to(:challenge) }
  end

  describe "validations" do
    subject { create(:poke) }

    it { should validate_presence_of(:poked_on) }

    it "validates uniqueness of poker scoped to pokee, challenge, and date" do
      existing = create(:poke)
      duplicate = build(:poke,
        poker: existing.poker,
        pokee: existing.pokee,
        challenge: existing.challenge,
        poked_on: existing.poked_on
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:poker_id]).to include("already poked this person today")
    end

    it "allows same poker/pokee pair on different dates" do
      existing = create(:poke, poked_on: Date.yesterday)
      new_poke = build(:poke,
        poker: existing.poker,
        pokee: existing.pokee,
        challenge: existing.challenge,
        poked_on: Date.current
      )
      expect(new_poke).to be_valid
    end

    it "allows same poker to poke different people on the same day" do
      existing = create(:poke)
      new_poke = build(:poke,
        poker: existing.poker,
        pokee: create(:user),
        challenge: existing.challenge,
        poked_on: existing.poked_on
      )
      expect(new_poke).to be_valid
    end

    it "does not allow self-poking" do
      user = create(:user)
      poke = build(:poke, poker: user, pokee: user)
      expect(poke).not_to be_valid
      expect(poke.errors[:base]).to include("Cannot poke yourself")
    end
  end
end
