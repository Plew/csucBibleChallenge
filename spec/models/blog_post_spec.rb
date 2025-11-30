require 'rails_helper'

RSpec.describe BlogPost, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
    it { should belong_to(:user) }
    it { should have_many(:blog_comments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_inclusion_of(:visible).in_array([ true, false ]) }
  end

  describe 'scopes' do
    let(:challenge) { create(:challenge) }
    let(:user) { create(:user, admin: true) }
    let!(:visible_post) { create(:blog_post, challenge: challenge, user: user, visible: true, created_at: 2.days.ago) }
    let!(:hidden_post) { create(:blog_post, challenge: challenge, user: user, visible: false, created_at: 1.day.ago) }
    let!(:newest_post) { create(:blog_post, challenge: challenge, user: user, visible: true, created_at: Time.current) }

    describe '.visible' do
      it 'returns only visible posts' do
        expect(BlogPost.visible).to include(visible_post, newest_post)
        expect(BlogPost.visible).not_to include(hidden_post)
      end
    end

    describe '.ordered' do
      it 'returns posts ordered by creation date descending' do
        expect(BlogPost.ordered).to eq([ newest_post, hidden_post, visible_post ])
      end
    end
  end

  describe '#author' do
    let(:user) { create(:user) }
    let(:blog_post) { create(:blog_post, user: user) }

    it 'returns the user who created the post' do
      expect(blog_post.author).to eq(user)
    end
  end

  describe 'deletion' do
    let(:blog_post) { create(:blog_post) }
    let!(:comment1) { create(:blog_comment, blog_post: blog_post) }
    let!(:comment2) { create(:blog_comment, blog_post: blog_post) }

    it 'destroys associated comments when deleted' do
      expect { blog_post.destroy }
        .to change(BlogComment, :count).by(-2)
    end
  end
end
