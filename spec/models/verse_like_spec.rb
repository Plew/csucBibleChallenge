require 'rails_helper'

RSpec.describe VerseLike, type: :model do
  describe 'associations' do
    it { should belong_to(:reading) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:verse_number) }
    it { should validate_numericality_of(:verse_number).only_integer.is_greater_than(0) }

    describe 'uniqueness' do
      let(:user) { create(:user) }
      let(:reading) { create(:reading) }

      before do
        create(:verse_like, user: user, reading: reading, verse_number: 1)
      end

      it 'prevents duplicate likes on the same verse by the same user' do
        duplicate = build(:verse_like, user: user, reading: reading, verse_number: 1)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include('has already liked this verse')
      end

      it 'allows different users to like the same verse' do
        other_user = create(:user)
        like = build(:verse_like, user: other_user, reading: reading, verse_number: 1)
        expect(like).to be_valid
      end

      it 'allows the same user to like different verses' do
        like = build(:verse_like, user: user, reading: reading, verse_number: 2)
        expect(like).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:reading1) { create(:reading) }
    let(:reading2) { create(:reading) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      create(:verse_like, reading: reading1, verse_number: 1, user: user1)
      create(:verse_like, reading: reading1, verse_number: 1, user: user2)
      create(:verse_like, reading: reading1, verse_number: 2, user: user1)
      create(:verse_like, reading: reading2, verse_number: 1, user: user1)
    end

    describe '.for_verse' do
      it 'returns likes for specific reading and verse number' do
        likes = VerseLike.for_verse(reading1.id, 1)
        expect(likes.count).to eq(2)
      end
    end

    describe '.by_user' do
      it 'returns likes by a specific user' do
        likes = VerseLike.by_user(user1)
        expect(likes.count).to eq(3)
      end
    end
  end

  describe 'version-agnostic liking' do
    let(:challenge) { create(:challenge) }
    let(:reading) { create(:reading, challenge: challenge, book_number: 1, chapter_number: 1) }
    let(:user1) { create(:user, version: 'KJV') }
    let(:user2) { create(:user, version: 'ESV') }

    it 'allows users with different Bible versions to like the same verse' do
      create(:verse_like, reading: reading, verse_number: 1, user: user1)
      create(:verse_like, reading: reading, verse_number: 1, user: user2)

      likes = VerseLike.for_verse(reading.id, 1)
      expect(likes.count).to eq(2)
    end
  end
end
