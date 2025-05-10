require 'rails_helper'

RSpec.describe Verse, type: :model do
  describe 'validations' do
    subject { FactoryBot.build(:verse) }

    it { should validate_presence_of(:version) }
    it { should validate_presence_of(:book_number) }
    it { should validate_numericality_of(:book_number).only_integer.is_greater_than_or_equal_to(1) }
    it { should validate_presence_of(:chapter_number) }
    it { should validate_numericality_of(:chapter_number).only_integer.is_greater_than_or_equal_to(1) }
    it { should validate_presence_of(:verse_number) }
    it { should validate_numericality_of(:verse_number).only_integer.is_greater_than_or_equal_to(1) }
    it { should validate_presence_of(:verse_text) }

    # Example for testing the commented-out uniqueness validation, if you implement it:
    # context 'uniqueness of verse_number' do
    #   before { FactoryBot.create(:verse, version: "KJV", book_number: 1, chapter_number: 1, verse_number: 1) }
    #   it { should validate_uniqueness_of(:verse_number).scoped_to(:version, :book_number, :chapter_number) }
    # end
  end

  it "is valid with valid attributes" do
    expect(FactoryBot.build(:verse)).to be_valid
  end
end
