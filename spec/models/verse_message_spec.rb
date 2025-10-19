require 'rails_helper'

RSpec.describe VerseMessage, type: :model do
  describe 'associations' do
    it { should belong_to(:reading) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:verse_number) }
    it { should validate_numericality_of(:verse_number).only_integer.is_greater_than(0) }
  end

  describe 'scopes' do
    let(:reading1) { create(:reading) }
    let(:reading2) { create(:reading) }
    let(:user) { create(:user) }

    before do
      create(:verse_message, reading: reading1, verse_number: 1, user: user, content: 'Message 1')
      create(:verse_message, reading: reading1, verse_number: 2, user: user, content: 'Message 2')
      create(:verse_message, reading: reading2, verse_number: 1, user: user, content: 'Message 3')
    end

    it 'for_verse returns messages for specific reading and verse number' do
      messages = VerseMessage.for_verse(reading1.id, 1)
      expect(messages.count).to eq(1)
      expect(messages.first.content).to eq('Message 1')
    end

    it 'recent orders by created_at desc' do
      messages = VerseMessage.recent
      expect(messages.first.content).to eq('Message 3')
    end
  end

  describe 'version-agnostic commenting' do
    let(:challenge) { create(:challenge) }
    let(:reading) { create(:reading, challenge: challenge, book_number: 1, chapter_number: 1) }
    let(:user1) { create(:user, version: 'KJV') }
    let(:user2) { create(:user, version: 'ESV') }

    it 'allows users with different Bible versions to see the same comments' do
      # User 1 (KJV) creates a comment on verse 1
      message = create(:verse_message, reading: reading, verse_number: 1, user: user1, content: 'Great verse!')

      # User 2 (ESV) should see the same comment when viewing verse 1
      messages = VerseMessage.for_verse(reading.id, 1)
      expect(messages.count).to eq(1)
      expect(messages.first.content).to eq('Great verse!')
      expect(messages.first.user).to eq(user1)
    end
  end
end
