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
    let!(:comment1) { create(:blog_comment, blog_post: blog_post, created_at: 3.days.ago) }
    let!(:comment2) { create(:blog_comment, blog_post: blog_post, created_at: 1.day.ago) }
    let!(:comment3) { create(:blog_comment, blog_post: blog_post, created_at: 2.days.ago) }

    describe '.ordered' do
      it 'returns comments ordered by creation date ascending' do
        expect(BlogComment.ordered).to eq([ comment1, comment3, comment2 ])
      end
    end
  end
end
