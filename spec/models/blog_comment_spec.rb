require 'rails_helper'

RSpec.describe BlogComment, type: :model do
  describe 'associations' do
    it { should belong_to(:blog_post) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
  end

  describe 'scopes' do
    let(:blog_post) { create(:blog_post) }
    let!(:old_comment) { create(:blog_comment, blog_post: blog_post, created_at: 2.days.ago) }
    let!(:new_comment) { create(:blog_comment, blog_post: blog_post, created_at: 1.day.ago) }

    describe '.recent_first' do
      it 'returns comments in reverse chronological order' do
        expect(BlogComment.recent_first.first).to eq(new_comment)
        expect(BlogComment.recent_first.last).to eq(old_comment)
      end
    end
  end
end
