require 'rails_helper'

RSpec.describe VerseLike, type: :model do
  describe 'associations' do
    it { should belong_to(:reading) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:verse_number) }
    it { should validate_numericality_of(:verse_number).only_integer.is_greater_than(0) }

    context 'uniqueness' do
      let(:user) { create(:user) }
      let(:reading) { create(:reading) }

      before do
        create(:verse_like, user: user, reading: reading, verse_number: 1)
      end

      it 'prevents duplicate likes from the same user on the same verse' do
        duplicate_like = build(:verse_like, user: user, reading: reading, verse_number: 1)
        expect(duplicate_like).not_to be_valid
        expect(duplicate_like.errors[:user_id]).to include('has already been taken')
      end

      it 'allows the same user to like different verses' do
        different_verse_like = build(:verse_like, user: user, reading: reading, verse_number: 2)
        expect(different_verse_like).to be_valid
      end
    end
  end

  describe 'verse likes functionality' do
    let(:challenge) { create(:challenge) }
    let(:reading) { create(:reading, challenge: challenge, book_number: 1, chapter_number: 1) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'allows multiple users to like the same verse' do
      like1 = create(:verse_like, reading: reading, verse_number: 1, user: user1)
      like2 = create(:verse_like, reading: reading, verse_number: 1, user: user2)

      expect(reading.verse_likes.where(verse_number: 1).count).to eq(2)
    end

    it 'tracks likes per verse' do
      create(:verse_like, reading: reading, verse_number: 1, user: user1)
      create(:verse_like, reading: reading, verse_number: 2, user: user1)
      create(:verse_like, reading: reading, verse_number: 1, user: user2)

      expect(reading.verse_likes.where(verse_number: 1).count).to eq(2)
      expect(reading.verse_likes.where(verse_number: 2).count).to eq(1)
    end
  end
end
